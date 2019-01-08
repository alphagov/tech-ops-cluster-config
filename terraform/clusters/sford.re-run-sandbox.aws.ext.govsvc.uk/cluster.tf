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
    key    = "sford.re-run-sandbox.aws.ext.govsvc.uk/cluster.tfstate"
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
  cluster_name = "sford"
  zone_name    = "run-sandbox.aws.ext.govsvc.uk"
  zone_id      = "Z23SW7QP3LD4TS"

  # configuration
  ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC2qSnPB0Be5/Im8b7HGH+Km0nJLexhMFewE47Jtt4Nsrv7nPduJ99cGndbXleVuRATZ9oqEhU2KrUGcfcEYXDABSrocM8mv7Iy7f7xQjEC/Qzm3CiHQ9xMWrBm3bUTWR+BbOJRuJqkUD1dd9VwxjbKYuz/RZxLGVRJk05KmVE83jAzr79OkPsDKdnEUnSu6QsgordWiS0oeCiMhsMOIWext2UtkIoA/VfeuqVb1ak5QfsDO8bjszyMiyMfcreajeyF1acs5LO+3OtHDjTK/Ln8an6DVhdf9/n4y1kLnh1ZgVJF7NqNdbPOV3zMl8fh7XnG7vJ2lLaXLSTyCO6UlLnVtmZk6Tnf64LDEOv2xjkOGledTi+IqLrnupCRotlsvPOTOaiiVG+S4YWbF4rwY7U4RD7AAyqjmnaSuXLI1xr0p7zAShvDvD8Rf6ZHhwLEEsFhJLeQirnnFwOM+e5L3i1hKTrI8IASpPkWEV7O4JWhS3x32gU5ON4EmQXE2BgEm7REYFh8egmLGLH2c7Vj+wDIH6FNQD4Werfj3IH+LxwiiiHJrXQtbcAGDn8P8dLqIkxXxkeRBOVAuPZqOOYtEnfwTK22axqCpzFvBQBgrLHyBL1oja4fMni/LqM1FVSQtP8QZCE3yv6Nc8+bK8y8YzOWqfgD8RDVlU3FmcHbooQGPQ== sford.re-run-sandbox.aws.ext.govsvc.uk"

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
  cluster_id = "sford.run-sandbox.aws.ext.govsvc.uk"
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
