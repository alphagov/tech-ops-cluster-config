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
    key    = "samcrang.run-sandbox.aws.ext.govsvc.uk/cluster.tfstate"
  }
}

variable "allowed_ips" {
  description = "A list of IP addresses permitted to access Kubernetes API Server"
  type        = "list"
}

variable "concourse_password" {
  description = "Concourse `main` user password"
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
  cluster_name = "samcrang"
  zone_name    = "run-sandbox.aws.ext.govsvc.uk"
  zone_id      = "Z23SW7QP3LD4TS"

  # configuration
  allowed_ips = "${var.allowed_ips}"

  ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/1wjFHifB/z1fgu0D0kHyRZa1fj/ngYHwJ43IQEh1lUgz7a/4qMa8c0rmzPWg7K6unCLATPmLardxNbYSfeaDgDJmz748AWZjxaAnsjX9hT+5N0gU6XoqKVsJr/wZT6vnEGOiJ3k6UDxOVlu1iWSoTjDecFMn3z80DB7CEkNmLM6ty55MvG/KvtNfLRg2LiMS+6KF26zK3SdjcVv74O7TRixp2q8tKqMnHC5Z2L2vHylNOgCU5U1GBXF5aFxLTkiItVrPXUyv3nAY3dbazO0Dd8G7kbPydGpRWiiTz3N1jgrDNwbxa1oyEuPQUPOdSyVV/XheP9s+KIEkGeBkyIuAWsppYFsBo+eHNfvvlf34wSpDFNGwE6z6Q8thmIaTA/Sp6OmsUmPKGtGkYaWgI2p9i7V1dQ6jYKYoruiMCMGlsVTIFae3g9qIO63WHtDfb3qVJwISK4CD0Dj9aYQ4oRoGReX3eH1YQALvRfm9fiEkT2J1p/vP/J+NDTU0lRt0haaGtI+QgmhfOXuK25Gc5ZmKD8AB1LCWVl+RkFKVdWpIy69Ru2TJbEOwHgSc6gwIjXfbgIjXdrP7Hqq7j+hCtRc0Ozeh6EAxqgO1u2yhzC+H1GZvXc7b9Ra8Zftzho1KTDUXcZMXYbVVJs0ogJPKmfHBKas4oHAIUy7MoDp2XjpZxw== samcrang.run-sandbox.aws.ext.govsvc.uk"

  concourse_main_password = "${var.concourse_password}"

  codecommit_url = "${module.gsp-base-applier.repo_url}"
  admin_role_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/admin"]
}

module "gsp-base-applier" {
  source = "../../modules/codecommit-kube-applier"

  repository_name        = "samcrang.run-sandbox.aws.ext.govsvc.uk.gsp-base"
  repository_description = "State of the gsp-base world!"
  namespace              = "gsp-base"
}
