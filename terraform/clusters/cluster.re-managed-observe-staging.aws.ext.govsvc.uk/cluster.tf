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
    bucket = "gds-re-managed-observe-staging-terraform-state"
    region = "eu-west-2"
    key    = "cluster.re-managed-observe-staging.aws.ext.govsvc.uk/cluster.tfstate"
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
  cluster_name = "cluster"
  zone_name    = "re-managed-observe-staging.aws.ext.govsvc.uk"
  zone_id      = "ZQQE7MLQRG73Z"

  # configuration
  ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDcM1gMH937SSS+gyXBeC4Xbi5Q9JU5E/zOQ8qmEVKJrDpwCzkkt/7amVSFaeYooLDsrjGxBBgcLadoQ0z33GvDzS5D2a8tZWxtrQAvN4o4B2QSksq54ZCte/j8QjLbgrRbpt0WNScuhZiW7NVmbhqfSZORYNW+FtGp24HIRpazLHH5y+36n8YD8liTWELG0ckiUO4JEKs58u6fPOFDQ+GKeuKxIoQEOngG2nOmSpYABo6KJujZ3KH403i7B1FCf3Aao2gXUkj7Oa79YUprDDF0yw5fXsSD0aF8VbKbySkxErBgAwww+bT/UJPdU0udt+T4jbKFkgedYU5pGnBKEOKb0RAZhb1Cecis82jhNxYP5No9TtE/2ZJjjAz6UtPQjrTlFmXNkNvQqvINY/OVCnsMfOdXopOuLdzlGNrkvIvjmiZQhOWHrNuKkQuQG9HCsywVt7g9xrpfsbMpyVAJnGJIv6yn4WcfJmVWmAXY0uzXiY6fyF7d+42EvXrm5jcJG6IBQsTtBj+X+quu0aFA+pfzMFgKGIJon3PX/fEECiu55ATQRYqIlm0xZlbG9wA98TRSuc0wCkUIqVnIo4QZbghAdWBneLpF++8m+65XxdRaCdmy6XjKV8H5NKEe/k1FNTQiWkx4I/TnkggGStfkl8HFmf1lxV8Mh5dwcf2xjOatyw== cluster.re-managed-observe-staging.aws.ext.govsvc.uk"

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

module "observe-alertmanager" {
  source = "../../modules/github-flux"

  namespace  = "alertmanager"
  chart_git  = "https://github.com/alphagov/gsp-observe-alertmanager-spike.git"
  chart_ref  = "master"
  chart_path = ""
}
