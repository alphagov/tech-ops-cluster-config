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
    bucket = "gds-re-run-sandbox-terraform-state"
    region = "eu-west-2"
    key    = "farms.re-run-sandbox.aws.ext.govsvc.uk/cluster.tfstate"
  }
}

data "aws_caller_identity" "current" {}

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
  cluster_name = "farms"
  zone_name    = "run-sandbox.aws.ext.govsvc.uk"
  zone_id      = "Z23SW7QP3LD4TS"

  # configuration
  ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCrrWSX0kfIfznu+ymRBVjSnD6+tbLhs6czXTWXGQcVesOjUTEco1fpzkels0GpsjYrKe+P773SYDZ6SJiFTAME7TKL7k7azG24T+z5fp2PzW/5EkzwEkgBUUQThoaG7wfpVDQjHMlmm2ddLOEEHesKRnH4qy8QoYHkfaHNA1iAbPUyfDqBeki/UcOjTdPwz0vhTnZeValdYLQ7gH9AFYcWzaI0JMyjfCzmS4C2q+sY8IDJ8oE/L4JjtUxKc/ahlV10hfQ/RAzIKWa8BcS1r+us54V2cgvEJpPJNKzA7UEm37Im4Q0sj9ncxnp8rKOPSqxDTKs+rvhx3vw3YPwcqnc7tAQwjODJvvybdEES4TMHZoVHCHQW03wIaMwL2viK2Jcv81mC5bfLhCgL8zsnBMprRNMAJ30Hrc5pCeaQqqpuRXncNQ85H34fneBLQn/KHpHUfZydHIFc52wrQyG58vQzqp/1juCst7n64a5SB7xCh7IGRkmjZ1muwt5q8QEUaFSD4JJQCivXC6yDX9cxpp/+KoR3FQt/ISKIk9L40ivqKj+2ONgM1zwLepZ7oKnW78SheOf23wG3x26tkumIu6ro0/7cJy85ua49fPqklH2c470zXHIgtkg5N/VipNp9E8Vt6jZRUSM1WpcUj2EPLVa5O2RI4yMrIGvLRiZcwV0CvQ== farms.re-run-sandbox.aws.ext.govsvc.uk"

  admin_role_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/admin"]
}

module "gsp-base-release" {
  source = "../../modules/github-flux"

  namespace  = "gsp-base"
  chart_git  = "https://github.com/alphagov/gsp-base.git"
  chart_ref  = "master"
  chart_path = "charts/base"
}

module "gsp-monitoring-release" {
  source = "../../modules/github-flux"

  namespace  = "monitoring-system"
  chart_git  = "https://github.com/alphagov/gsp-monitoring.git"
  chart_ref  = "master"
  chart_path = "monitoring"
}
