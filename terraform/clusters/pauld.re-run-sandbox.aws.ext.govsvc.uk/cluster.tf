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
    key    = "pauld.re-run-sandbox.aws.ext.govsvc.uk/cluster.tfstate"
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
  cluster_name = "pauld"
  zone_name    = "run-sandbox.aws.ext.govsvc.uk"
  zone_id      = "Z23SW7QP3LD4TS"

  # configuration
  ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDrRoAgyS6SoPYQ1lItEJwCBkYw/hYRWb+ap20cINdPIn+xLeRKqV21ORUE2h2qneX6J6zpHYXVRHWUbqdFU8H9zGKog2x23euCkCYx7kNb6bZc+zbjXCCidiY7GpK9lSrZ9tmxbcZxa5qFrX93/xN+rsCJzdL2yTk0e4mhMCF5taKN3vHM//ml0zGhI95MM6QyUQUoCMn1m8yw+erBUrdnTVNz9PSnPyspMp4+s+uVee18t5svMEm+c9/uoUXt52urm7nijaDYaByM7zJ81ld3kWaAK6lwUh/oG8nLMshR0Gx3Uay8Ht5WxTGBrNM8kzNGwPRR3mo8i3zatMk0ByV69U9RUbekH3ZUa++Zv71Kc13l2PjBQJBULE7OFvCmeY58/Qn6pbtR6h0nvODo6nP9LRjCMZ8WJKim0LOSfNSwsZK3/DFUTP8rXMjUojZf59qUB7hAZ0cBGqQQJoq6HFU81+GoICqaG2AKJYGwEJDJhwhTo6G1NU0tYOq/sxvVxUJU49HNUthL72dS3gbBdUKfCYiDGBw/bdiyUvXkm0/I9vSpPMan5R0Dr8Wi9YSMpKoS1dGKuAdW+8E0fu2pZzn3/xPkv4K0KtQUQBcDIYvJujgjC20qPEbv6qw49WNkR9l2A8C2bdMIoP4LhW4POaJMewSTmmgADNMJ4c1hsB66cw== pauld.re-run-sandbox.aws.ext.govsvc.uk"

  admin_role_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/admin"]
}

module "gsp-base-flux-helm" {
  source = "../../modules/github-flux"

  namespace = "gsp-base"
  chart_git  = "https://github.com/alphagov/gsp-base.git"
  chart_ref  = "master"
  chart_path = "charts/base"
  cluster_name = "${module.cluster.cluster_name}"
  cluster_domain = "${module.cluster.cluster_name}.${module.cluster.zone_name}"
}

module "gsp-monitoring-release" {
  source = "../../modules/github-flux"

  namespace  = "monitoring-system"
  chart_git  = "https://github.com/alphagov/gsp-monitoring.git"
  chart_ref  = "master"
  chart_path = "monitoring"
  cluster_name = "${module.cluster.cluster_name}"
  cluster_domain = "${module.cluster.cluster_name}.${module.cluster.zone_name}"
}

module "gsp-canary" {
  source     = "../../modules/canary"
  cluster_id = "pauld.run-sandbox.aws.ext.govsvc.uk"
}

module "gsp-sealed-secrets" {
  source = "../../modules/github-flux"

  namespace  = "secrets-system"
  chart_git  = "https://github.com/alphagov/gsp-sealed-secrets.git"
  chart_ref  = "master"
  chart_path = "charts/sealed-secrets"
  cluster_name = "${module.cluster.cluster_name}"
  cluster_domain = "${module.cluster.cluster_name}.${module.cluster.zone_name}"
}
