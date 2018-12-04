provider "aws" {
  region  = "(AWS_REGION)"
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
    bucket = "gds-(AWS_ACCOUNT_NAME)-terraform-state"
    region = "eu-west-2"
    key    = "(CLUSTER_NAME).(AWS_ACCOUNT_NAME).(CLOUD).(SYSTEM_DOMAIN)/cluster.tfstate"
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
  cluster_name = "(CLUSTER_NAME)"
  zone_name    = "(ZONE_NAME)"
  zone_id      = "(ZONE_ID)"

  # configuration
  ssh_authorized_key = "(PUBLIC_SSH_KEY)"

  admin_role_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/admin"]
}

module "gsp-base-flux-helm" {
  source = "../../modules/github-flux"

  namespace = "gsp-base"
  chart_git  = "https://github.com/alphagov/gsp-base.git"
  chart_ref  = "master"
  chart_path = "charts/base"
}
