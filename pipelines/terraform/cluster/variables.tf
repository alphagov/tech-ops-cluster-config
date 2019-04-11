variable "aws_account_role_arn" {
  type = "string"
}

variable "gsp_version_ref" {
  description = "the git ref/branch to pull gsp modules from"
  type = "string"
  default = "master"
}

variable "persistent_state_workspace" {
  type = "string"
}

variable "persistent_state_bucket_name" {
  type = "string"
}

variable "persistent_state_bucket_key" {
  type = "string"
}

variable "account_name" {
  type = "string"
}

variable "cluster_name" {
  type = "string"
}

variable "dns_zone" {
  type = "string"
}

variable "github_client_id" {
  type = "string"
}

variable "github_client_secret" {
  type = "string"
}

variable "splunk_hec_url" {
  type = "string"
}

variable "splunk_hec_token" {
  type = "string"
}

variable "splunk_index" {
  type = "string"
  default = "run_sandbox_k8s"
}

variable "worker_instance_type" {
  type = "string"
  default = "m5.large"
}

variable "worker_count" {
  type = "string"
  default = "3"
}

variable "ci_worker_instance_type" {
  type = "string"
  default = "m5.large"
}

variable "ci_worker_count" {
  type = "string"
  default = "3"
}
