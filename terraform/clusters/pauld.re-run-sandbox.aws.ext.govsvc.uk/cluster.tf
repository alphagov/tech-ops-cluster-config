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
  ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCrBaAZsVUxjCS409KMgsSYaa8xHWXj3AEn1sbAxXpTkfgEsGiD3jDAQ4UEbVO6u6O0YwsA47YsWW5w8SBd2uD6Ewqj4jEoUN/7j/6jIis6enPaWiGhkRgus+LVC0OKrcpZS0ujEdIKbLkdA1fIBTkt1jEkFFXDXoWP+ba+wfwhRGRo8AAGUcZi7fcY3Jeq/qY15VgjnomlRmGV5dge5VQdMIcovhvcEM57Tg2UgQ2WI3sCuiBNKG0RJiIfiZk1U74QIqFPzEPsNHOfEKq1Y7AA0jleQWl+7uk0vEGAa7ifOc0jB4fUNbo/smoFjt3MA4qFIPBQe7apyOQ6JPwnbzq+93/UaMPWbBhOVaPXHsez9XQEPofGMcOyNzrFkibdyOUS/1w7lFhAcQ4XUDCiqFeMClvRTpys12LQT1qsHWQ9Qrzw0i/osxqX3LtU0uZ3GkDTzKEzBOxTF5UDOIw4sKjjm++bt0aees+aSdmvfCtiDLB4B6V1n483ddJ7fmJazYyoRFTmMtKN7Q9252bsqjz7Fhjbfbcb1Y7YoDRpFzZzLXjFyrhM8fTVs2tT5fISucC7F9dSzsWlbdM9UaiEmenhPUToOcWEskZLZPWppx5O4KkfL4U5xneP6vZZLL9scjM8whsPRhFCUxeThRMdRYhZsCcpL7XCfd8YwhA6qRXqRQ== pauld.re-run-sandbox.aws.ext.govsvc.uk"

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
