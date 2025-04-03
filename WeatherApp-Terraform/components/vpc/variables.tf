variable "default_tags" {
  type        = map(string)
  default     = {}
  description = "Default tags"
}

variable "create_nat_gateway" {
  type        = bool
  default     = true
  description = "Whether to create a NAT gateway for private subnets"
}

variable "environment" {
  type        = string
  description = "Environment to run"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks for public subnets"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks for private subnets"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones to use for subnets"
}
