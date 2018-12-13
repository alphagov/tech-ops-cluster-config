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
    key    = "danielblair.run-sandbox.aws.ext.govsvc.uk/cluster.tfstate"
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
  cluster_name = "danielblair"
  zone_name    = "run-sandbox.aws.ext.govsvc.uk"
  zone_id      = "Z23SW7QP3LD4TS"

  # configuration
  ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+VxGpNqOedPU7BqUGg+PA3KDaNe8kx75Gq0b+FxAuthUz0tZ9zqxZkr5ReikMH44V9OqRHPnF7yPgki/KyyETDffCt7eOaC+79WEPSADeHC64v5HkkIkR92+72/4HZpaNg5cGdpzcTo1SYWyy8Zo4Wf822fdoiBDXuwMM0js/prFz8UYbcK3R7xfkmZNrfOvYIHQ4ES1xHlT0x7v4NOeeZgJVRp+yD4WJBZZbVW5Szd02X8+dVAKKj5N3hqssCxJtXgx6JHTZt+T9a9S3Q9YCMJg02CZiWaA1k0s6Ko2a/3K79UZQQt8kLbTx1vy5QFarPTYktnQVPXX1rp8YueefOhSmffoVZEsaK6t4kQmEFKvbhbXrGTtrVgMpSe0F6Fb44BYfRHK+72fEtfC7xZT9dIQM8WcyK+ovaasu0R31zZMZGnU96GwKbDimFmlc1IgkaMlELfDJxek30X7p2KuWvDsSM3vLEc8ezREG5z89nOhFmhLvOr8wPmJOqzJkGp/okaD7pD1lDiAb7zNMjaGRxMDtQEYFlHLz+mdM/MYEWY3uSBsb59toAGT03PMfzwdXwWy2jEG6oTkBkrCLu0MIsURqaAjgJenxWtfgQ5us8E4p/QToVD1hUnZzz1zL9vP4NToKCpipE3NcugX/KsGdR3MGcJQEJOoLB1dfTP0mRQ== danielblair.run-sandbox.aws.ext.govsvc.uk"

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
  cluster_id = "danielblair.run-sandbox.aws.ext.govsvc.uk"
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
