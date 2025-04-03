module "eks" {
  source = "../../modules/eks"

  environment                  = var.environment
  cluster_name                 = var.cluster_name
  kubernetes_version           = var.kubernetes_version
  region                       = var.region
  vpc_id                       = var.vpc_id
  subnet_ids                   = var.subnet_ids
  node_group_subnet_ids        = var.node_group_subnet_ids
  enabled_cluster_log_types    = var.enabled_cluster_log_types
  cluster_encryption_cmk_arn   = var.cluster_encryption_cmk_arn
  endpoint_private_access      = var.endpoint_private_access
  endpoint_public_access       = var.endpoint_public_access
  control_plane_allowed_ip_ranges = var.control_plane_allowed_ip_ranges
  default_tags                 = var.default_tags
}

# Resource to update kubeconfig
resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${var.cluster_name} --region ${var.region}"
  }

  depends_on = [module.eks]
}

# Set up the Vertical Pod Autoscaler
resource "null_resource" "install_vpa" {
  provisioner "local-exec" {
    command = <<-EOT
      # Create and navigate to temporary directory for VPA installation
      TMP_DIR=$(mktemp -d)
      cd $TMP_DIR
      git clone https://github.com/kubernetes/autoscaler.git
      cd autoscaler/vertical-pod-autoscaler
      bash hack/vpa-up.sh
      rm -rf $TMP_DIR
    EOT
  }

  depends_on = [null_resource.update_kubeconfig]
}
