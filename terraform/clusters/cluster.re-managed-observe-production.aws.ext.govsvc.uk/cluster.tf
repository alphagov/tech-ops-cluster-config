provider "aws" {
  region  = "eu-west-2"
  version = "~> 1.41"
  alias   = "default"
}

provider "local" {
  version = "~> 1.0"
  alias   = "default"
}

provider "null" {
  version = "~> 1.0"
  alias   = "default"
}

provider "template" {
  version = "~> 1.0"
  alias   = "default"
}

provider "tls" {
  version = "~> 1.0"
  alias   = "default"
}

terraform {
  backend "s3" {
    bucket = "gds-re-managed-observe-production-terraform-state"
    region = "eu-west-2"
    key    = "cluster.re-managed-observe-production.aws.ext.govsvc.uk/cluster.tfstate"
  }
}

variable "allowed_ips" {
  description = "A list of IP addresses permitted to access Kubernetes API Server"
  type        = "list"
}

variable "concourse_password" {
  description = "Concourse `main` user password"
}

module "cluster" {
  source = "../../modules/gsp-cluster"

  providers = {
    aws      = "aws.default"
    local    = "local.default"
    null     = "null.default"
    template = "template.default"
    tls      = "tls.default"
  }

  # AWS
  cluster_name = "cluster"
  zone_name    = "re-managed-observe-production.aws.ext.govsvc.uk"
  zone_id      = "Z3PP5INJVJEM4"

  # configuration
  allowed_ips = "${var.allowed_ips}"

  ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDWCjS006oRGlPoILF3z8r6AZcT239VrUI3ch1UK69EjfFqUq76Og67tGHhdX5ZWzoICMThTk2OsPoVdrq9k+DeKEDhw/VM+rMRfXbnmZag+ENftAPdj4crifX77egnLs2OO4fZhvJcCjUutPYj1gZq+sK+QxFjxGv2r+w/eFwieSBUKn5cq8oC+GWejo3HEhvYFa34ETiFatRgwmWBYR2HQdxMHahQSd6jWXMJjTFScEMaEbhnncbSzHeh/NGtAFbaQ4qRaFf81HyMxeQ+By8DtcPvxgSPbYB8pmyfoW3ZSWR5C249oSpwDNjUwGzS1ka0utkpcOVIIfxcK/f5o3QxGV4xE52bKviTfjEVNy8DNm7g+yScsxR3L5n3AlEgNquWdBVSRJ8X5tmUEv/dYZ0+b/0hKo5powMq+MOrczuwiFXGawHi7BUbQBhwjEYdfm55X9jVJ/cdZQ1S3cS9ao9/eUqsKT442Zhn6QqrKXLa/2RlbwYgmRipxJNQI8YJdRIayNOoGK5dlav9nt0gYagIyHQ6cB9ePv58J4YB5VN5xeb1VVYmA6duc5nMDczNqqgfHWNEMThP6w8U/I0wCbi+JkeKSVdrDIL5Jltb1w6EWZ7KvmiGwJQ/Q1ZI6v7aC6zVyF4V8G2L8o9qrpDAfHDQU/MkhnW0cbk93nVUun1Rhw== cluster.re-managed-observe-production.aws.ext.govsvc.uk"

  concourse_main_password = "${var.concourse_password}"

  codecommit_url = "${module.gsp-base-applier.repo_url}"
}

module "gsp-base-applier" {
  source = "../../modules/codecommit-kube-applier"

  repository_name        = "cluster.re-managed-observe-production.aws.ext.govsvc.uk.gsp-base"
  repository_description = "State of the gsp-base world!"
  namespace              = "gsp-base"
}
