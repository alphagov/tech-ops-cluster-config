variable "aws_account_role_arn" {
  description = "ARN of the role in which this is being run"
  type        = "string"
}

variable "cluster_name" {
  description = "Name of the cluster"
  type        = "string"
}

variable "dns_zone" {
  description = "The apex domain associated with this cluster"
  type        = "string"
}

