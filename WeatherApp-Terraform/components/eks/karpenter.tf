data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}


# Set up the Helm provider for Karpenter
provider "helm" {
  kubernetes {
    host                   = module.eks.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
      command     = "aws"
    }
  }
}

# Create IAM role for Karpenter
resource "aws_iam_role" "karpenter_controller" {
  name = "karpenter-controller-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = module.eks.eks_cluster_oidc
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${module.eks.eks_cluster_oidc}:aud" : "sts.amazonaws.com",
          "${module.eks.eks_cluster_oidc}:sub" : "system:serviceaccount:karpenter:karpenter"
        }
      }
    }]
  })

  tags = var.default_tags
}

# Create IAM policy for Karpenter
resource "aws_iam_policy" "karpenter_controller" {
  name = "KarpenterController-${var.cluster_name}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "ec2:TerminateInstances",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeSpotPriceHistory",
          "pricing:GetProducts",
          "ssm:GetParameter",
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_controller" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller.arn
}

# Create instance profile for Karpenter nodes
resource "aws_iam_instance_profile" "karpenter" {
  name = "KarpenterNodeInstanceProfile-${var.cluster_name}"
  role = module.eks.node_group_role
}

# Create Karpenter namespace
resource "kubernetes_namespace" "karpenter" {
  metadata {
    name = "karpenter"
  }
  depends_on = [module.eks]
}

# Install Karpenter using Helm
resource "helm_release" "karpenter" {
  namespace        = kubernetes_namespace.karpenter.metadata[0].name
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "1.3.3"
  create_namespace = false

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter_controller.arn
  }

  set {
    name  = "settings.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = module.eks.eks_cluster_endpoint
  }

  set {
    name  = "settings.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter.name
  }

  depends_on = [
    kubernetes_namespace.karpenter,
    aws_iam_role_policy_attachment.karpenter_controller
  ]
}


resource "aws_ec2_tag" "subnet_tags" {
  for_each    = toset(var.node_group_subnet_ids)
  resource_id = each.value
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}


/*
# Create a default Karpenter NodePool
 resource "kubernetes_manifest" "karpenter_nodepool" {
   manifest = <<-EOF
 apiVersion: karpenter.sh/v1
 kind: NodePool
 metadata:
   name: default
 spec:
   template:
     spec:
       requirements:
         - key: karpenter.sh/capacity-type
           operator: In
           values: ["on-demand"]
         - key: kubernetes.io/arch
           operator: In
           values: ["amd64"]
         - key: node.kubernetes.io/instance-type
           operator: In
           values: 
           - m1.large
           - m1.medium
           - m1.2xlarge
       nodeClassRef:
         name: default
   limits:
     cpu: 10
     memory: 20Gi
   disruption:
     budgets:
     - nodes: 10%
     consolidationPolicy: WhenEmptyOrUnderutilized
     consolidateAfter: 30s
 EOF
   depends_on = [helm_release.karpenter]
 }

# # Create Karpenter EC2NodeClass
 resource "kubernetes_manifest" "karpenter_ec2nodeclass" {
   manifest = <<-EOF
 apiVersion: karpenter.k8s.aws/v1beta1
 kind: EC2NodeClass
 metadata:
    name: default
    finalizers:
    - karpenter.k8s.aws/termination
 spec:
   amiFamily: AL2
   amiSelectorTerms:
   - alias: al2@latest
   subnetSelector:
     karpenter.sh/discovery: "${var.cluster_name}"
   securityGroupSelector:
     karpenter.sh/discovery: "${var.cluster_name}"
 EOF
   depends_on = [helm_release.karpenter]
 }
*/


resource "kubernetes_manifest" "karpenter_nodepool" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata   = {
      name = "default"
    }
    spec = {
      template = {
        spec = {
          requirements = [
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["on-demand"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values   = ["m1.large", "m1.medium", "m1.2xlarge"]
            }
          ]
          nodeClassRef = {
            name = "default"
          }
        }
      }
      limits = {
        cpu    = 10
        memory = "20Gi"
      }
      disruption = {
        budgets = [
          {
            nodes = "10%"
          }
        ]
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter    = "30s"
      }
    }
  }
  depends_on = [
    module.eks,
    helm_release.karpenter
  ]
}

# Similarly, update the EC2NodeClass manifest
resource "kubernetes_manifest" "karpenter_ec2nodeclass" {
  manifest = {
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "default"
      finalizers = ["karpenter.k8s.aws/termination"]
    }
    spec = {
      amiFamily = "AL2"
      amiSelectorTerms = [
        {
          alias = "al2@latest"
        }
      ]
      subnetSelector = {
        "karpenter.sh/discovery" = var.cluster_name
      }
      securityGroupSelector = {
        "karpenter.sh/discovery" = var.cluster_name
      }
    }
  }
  depends_on = [
    module.eks,
    helm_release.karpenter
  ]
}
