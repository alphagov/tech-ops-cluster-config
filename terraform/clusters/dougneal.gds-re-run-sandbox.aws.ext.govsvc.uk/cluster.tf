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
    key    = "dougneal.gds-re-run-sandbox.aws.ext.govsvc.uk/cluster.tfstate"
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
  cluster_name = "dougneal"
  zone_name    = "run-sandbox.aws.ext.govsvc.uk"
  zone_id      = "Z23SW7QP3LD4TS"

  # configuration
  ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDZd2hu1lqFcT/pTG4Twwmr0PwnkAcywnygrJgB4os5ieEUCnv2r+ZedsTSdeRSRx+04ltM/7CZReKkutAX4IRx2Ngmmyagq7Ai9gdSw5NC2FNHviKOAo+1CMLUJeLTZ5NcaTGUg3RK81D0WiuZfTm4gJ05jLZwVspKk9O5IKnhugqmiPNsopm50QVBluF+L4Cb9MFQAvzHQ83esQ750LdisWoss8zEJURt14UkxDIu9PIiwh2HJj8yHA8HFYsbKY3ZtX1L83+KH2+iLvo3P6bmjIUFBwHgm/vcdPsCT3Y8aEXohE1QjOdeA5aFoqHbjk382qOsktz+nCD6s5yEQLpRBvxmUqf/t6vSXEPg7n2OsU0/+yvoRTZW3VV2mDHmlN+QT5HRSneiRYWFS8dzZOUaAVohZLhlcquQu6R/NYLZwYCSoPz997/NQ0e5wS7Pxa+pIDIqPeRmGUNXRRGjFgx6ArFZV1gVkjmOaeZLStUc2OAGmPvJbj8OVIK4rYm1jYj4xIh6YxzKefyeSH5o7Jdl5Y4o9mnTxcoNOvmvCrvhGjSddQvlkfRquFPbFqNFUXxJm2isKOGhTBxmuJKWlVV9g8IGutYpyQtWRWpPBYoQvlNKUD2lv6RoWAiWXykl/0Uv2XLVt1Ec7M0VTBqXADJCr53CGsovi3LlD/jdB8oPpQ== dougneal.gds-re-run-sandbox.aws.ext.govsvc.uk"

  admin_role_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/admin"]
}

module "gsp-base-release" {
  source = "../../modules/github-flux"

  namespace  = "gsp-base"
  chart_git  = "https://github.com/alphagov/gsp-base.git"
  chart_ref  = "master"
  chart_path = "charts/base"
  cluster_name = "${module.cluster.cluster_name}"
  cluster_domain = "${module.cluster.cluster_name}.${module.cluster.zone_name}"
}

module "gsp-canary" {
  source     = "../../modules/canary"
  cluster_id = "dougneal.run-sandbox.aws.ext.govsvc.uk"
}
