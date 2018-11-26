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
  zone_name    = "re-managed-observe-staging.aws.ext.govsvc.uk"
  zone_id      = "ZQQE7MLQRG73Z"

  # configuration
  allowed_ips = "${var.allowed_ips}"

  ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDcM1gMH937SSS+gyXBeC4Xbi5Q9JU5E/zOQ8qmEVKJrDpwCzkkt/7amVSFaeYooLDsrjGxBBgcLadoQ0z33GvDzS5D2a8tZWxtrQAvN4o4B2QSksq54ZCte/j8QjLbgrRbpt0WNScuhZiW7NVmbhqfSZORYNW+FtGp24HIRpazLHH5y+36n8YD8liTWELG0ckiUO4JEKs58u6fPOFDQ+GKeuKxIoQEOngG2nOmSpYABo6KJujZ3KH403i7B1FCf3Aao2gXUkj7Oa79YUprDDF0yw5fXsSD0aF8VbKbySkxErBgAwww+bT/UJPdU0udt+T4jbKFkgedYU5pGnBKEOKb0RAZhb1Cecis82jhNxYP5No9TtE/2ZJjjAz6UtPQjrTlFmXNkNvQqvINY/OVCnsMfOdXopOuLdzlGNrkvIvjmiZQhOWHrNuKkQuQG9HCsywVt7g9xrpfsbMpyVAJnGJIv6yn4WcfJmVWmAXY0uzXiY6fyF7d+42EvXrm5jcJG6IBQsTtBj+X+quu0aFA+pfzMFgKGIJon3PX/fEECiu55ATQRYqIlm0xZlbG9wA98TRSuc0wCkUIqVnIo4QZbghAdWBneLpF++8m+65XxdRaCdmy6XjKV8H5NKEe/k1FNTQiWkx4I/TnkggGStfkl8HFmf1lxV8Mh5dwcf2xjOatyw== cluster.re-managed-observe-staging.aws.ext.govsvc.uk"

  concourse_main_password = "${var.concourse_password}"

  codecommit_url = "${module.gsp-base-applier.repo_url}"
}

module "gsp-base-applier" {
  source = "../../modules/codecommit-kube-applier"

  repository_name        = "cluster.re-managed-observe-staging.aws.ext.govsvc.uk.gsp-base"
  repository_description = "State of the gsp-base world!"
  namespace              = "gsp-base"
}

module "observe-applier" {
  source = "../../modules/codecommit-kube-applier"

  repository_name        = "cluster.re-managed-observe-staging.aws.ext.govsvc.uk.gsp-observe"
  repository_description = "Alertmanager et al"
  namespace              = "observe"
}
