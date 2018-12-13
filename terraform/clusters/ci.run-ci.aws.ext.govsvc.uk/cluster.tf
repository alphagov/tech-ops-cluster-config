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
    bucket = "gds-re-run-ci-terraform-state"
    region = "eu-west-2"
    key    = "cluster.re-run-ci.aws.ext.govsvc.uk/cluster.tfstate"
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
  cluster_name = "ci"
  zone_name    = "run-ci.aws.ext.govsvc.uk"
  zone_id      = "Z1H4OPU70D5C3X"

  # sizing
  worker_count = 1
  worker_type  = "t3.medium"

  # configuration
  ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDJZdSJ0vgAg7frFYxRHuxM7LvMMEMzdqr1V2RzFvJ7dylCjxsNjlIddGn/y94W4GHf5XRXVof8Q3A27RUkbbxtFGvJy2egt0c12pvMEBl+8R6kICs3/NP4EHoPxY0lrpFmKjiAfOGI0kEV9s8jusQXwF9+o4ZR/UY6P8g5wqJxwWcdWwaHdGiv2ixaASfIGEmnyKzkF/GMKVYHGBKNsm7MXBnzVFiJqMIdvqjUNiGgvMS2XzYiLOyzNLHCJHJDkz+kKd+A/3ybUxYWyimz0NnzLfZSIiuGi1APxnbAIejVM/nXCdSOsZuX0mFqBnTjtglRUdvlfvbOJmrtPRs5sTul5LvMPnVxxz87JRSeF60F53azdbakSwDPMHHd9qb1a4Bdkv/Ck8ALPcQNjkGdfasErP0iA0+ZHGU61CF4rSW9xaBziD9+zRwxxNChJbkF1oIynDo2r8hYyd35C9AkR81oHdjBhdOssWkNYdPp5vGc56jr+rVPMcOW9axLQIn3LV4plAzvlsJaeakvazI4SLx2SY9XgYy8j+Z1AhINL5Dz27ZHlPIjUUScOLB1uAndZJ4Hbx7gLu/0If+z6qJ/0zfVPrGIgZKaPR8MFdL+Ldh2KTH5wb5AcFnnT4ORf8DdxBmIItK2aaK7/rM0T2fPQjp6XEDGAPffgrGC7MVSiA2EHQ== cluster.re-run-ci.aws.ext.govsvc.uk"

  admin_role_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/admin"]
}

module "gsp-base-release" {
  source = "../../modules/github-flux"

  namespace      = "gsp-base"
  chart_git      = "https://github.com/alphagov/gsp-base.git"
  chart_ref      = "master"
  chart_path     = "charts/base"
  cluster_name   = "${module.cluster.cluster_name}"
  cluster_domain = "${module.cluster.cluster_name}.${module.cluster.zone_name}"
}

module "gsp-monitoring-release" {
  source = "../../modules/github-flux"

  namespace      = "monitoring-system"
  chart_git      = "https://github.com/alphagov/gsp-monitoring.git"
  chart_ref      = "master"
  chart_path     = "monitoring"
  cluster_name   = "${module.cluster.cluster_name}"
  cluster_domain = "${module.cluster.cluster_name}.${module.cluster.zone_name}"
}

module "gsp-canary" {
  source     = "../../modules/canary"
  cluster_id = "cluster.re-run-ci.aws.ext.govsvc.uk"
}

module "gsp-sealed-secrets" {
  source = "../../modules/github-flux"

  namespace      = "secrets-system"
  chart_git      = "https://github.com/alphagov/gsp-sealed-secrets.git"
  chart_ref      = "master"
  chart_path     = "charts/sealed-secrets"
  cluster_name   = "${module.cluster.cluster_name}"
  cluster_domain = "${module.cluster.cluster_name}.${module.cluster.zone_name}"
}

module "gsp-ci-system" {
  source = "../../modules/github-flux"

  namespace      = "ci-system"
  chart_git      = "https://github.com/alphagov/gsp-ci-system.git"
  chart_ref      = "master"
  chart_path     = "charts/ci"
  cluster_name   = "${module.cluster.cluster_name}"
  cluster_domain = "${module.cluster.cluster_name}.${module.cluster.zone_name}"
}

module "gsp-concourse-ci-pipelines" {
  source = "../../modules/github-flux"

  namespace      = "${module.gsp-ci-system.release-name}-main"
  chart_git      = "https://github.com/alphagov/gsp-ci-pipelines.git"
  chart_ref      = "master"
  chart_path     = "charts/pipelines"
  cluster_name   = "${module.cluster.cluster_name}"
  cluster_domain = "${module.cluster.cluster_name}.${module.cluster.zone_name}"
}
