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
    bucket = "gds-re-(AWS_ACCOUNT_NAME)-terraform-state"
    region = "eu-west-2"
    key    = "(CLUSTER_NAME).(AWS_ACCOUNT_NAME).(CLOUD).(SYSTEM_DOMAIN)/cluster.tfstate"
  }
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
  cluster_name = "(CLUSTER_NAME)"
  zone_name    = "(ZONE_NAME)"
  zone_id      = "(ZONE_ID)"

  # configuration
  ssh_authorized_key = "(PUBLIC_SSH_KEY)"

  concourse_main_password = "${var.concourse_password}"

  codecommit_url = "${module.gsp-base-applier.repo_url}"
}

module "gsp-base-applier" {
  source = "../../modules/codecommit-kube-applier"

  repository_name = "(CLUSTER_NAME).(ZONE_NAME).gsp-base"
  repository_description = "State of the gsp-base world!"
  namespace = "gsp-base"
}
