output "eks_cluster_id" {
  description = "EKS Cluster ID"
  value       = aws_eks_cluster.this.id
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "value of certificate_authority_data for kubeconfig"
  value       = aws_eks_cluster.this.certificate_authority.0.data
}

output "node_group_role" {
  description = "Managed Node Groups"
  value       = aws_iam_role.node_group_role.name
}


output "eks_cluster_oidc" {
  description = "EKS Cluster Endpoint"
  value       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.this.identity.0.oidc.0.issuer, "https://", "")}"
}

output "eks_cluster_arn" {
  description = "EKS Cluster ARN"
  value       = aws_eks_cluster.this.arn
}



output "eks_cluster_security_group" {
  description = "EKS Cluster Security Group ID"
  value       = aws_security_group.control_plane_sg.id
}
