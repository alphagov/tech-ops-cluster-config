variable "aws_account_role_arn" {
  description = "Deployer role ARN from the target account"
  type = "string"
}

variable "account_name" {
  description = "Name of the account"
  type = "string"
}

variable "cluster_name" {
  description = "Name of the cluster"
  type        = "string"
}

variable "dns_zone" {
  description = "The apex domain associated with this cluster"
  type        = "string"
}

