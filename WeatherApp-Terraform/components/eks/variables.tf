variable "control_plane_allowed_ip_ranges" {
  type        = list(string)
  default     = []
  description = "List of allowed CIDR blocks for the EKS control plane"
}

variable "default_tags" {
  type        = map(string)
  default     = {}
  description = "Default tags to apply to all resources"
}

variable "environment" {
  type        = string
  description = "Environment, for example dev or prod"
}

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for the EKS cluster"
}

variable "region" {
  type        = string
  description = "AWS region for the EKS cluster"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the EKS cluster will be deployed"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the EKS cluster"
}

variable "enabled_cluster_log_types" {
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
  description = "List of log types to enable for the EKS control plane"
}

variable "cluster_encryption_cmk_arn" {
  type        = string
  description = "KMS key ARN for encrypting EKS secrets"
}

variable "endpoint_private_access" {
  type        = bool
  default     = true
  description = "Enable private access for the EKS endpoint"
}

variable "endpoint_public_access" {
  type        = bool
  default     = false
  description = "Enable public access for the EKS endpoint"
}

variable "node_group_subnet_ids" {
  type = list(string)
}

variable "node_group_desired_size" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 2
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 5
}

variable "node_group_instance_types" {
  description = "List of EC2 instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_disk_size" {
  description = "Disk size for the node group instances (in GB)"
  type        = number
  default     = 20
}
