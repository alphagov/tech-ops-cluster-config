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
    key    = "test.run-sandbox.aws.ext.govsvc.uk/cluster.tfstate"
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
  cluster_name = "test"
  zone_name    = "run-sandbox.aws.ext.govsvc.uk"
  zone_id      = "Z23SW7QP3LD4TS"

  # configuration
  allowed_ips = "${var.allowed_ips}"

  ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDPecLckzlW96r34QS4Hy7sSz3SiUt2Z+U0IBmTtzIx43g0VANul1jDZM9MXxQuPR8UUUL3h1O2zKWEyo7b9H4cq9KlKdHOJqGq9q/0ulcXr2NKt4yuzS7s6bcGnteWaUXnmW4MfOfluZsQbOlv/6GcZd4xSB2uP+wpZiW62lOKnbMQE6BuaOTteNyN6kcGuFgvQJPEDGaSf6FVwE5OagZ2VfeVYfYr9v3ZMIId/wSbUzSjv3TEGJpy4UYRe8/2MLoPtsYttzCd8Wt3XJT1Pdg0L/Em/vnisxlaH4I91riwKW6kFxGA0WaoTkFs++EbwwVfDidjCdF03Xs3gPfDjVHlwoecRMHzAgaR2CMa0/PH023Q+mq4oX7csAbJSP6tK3uwwCFYNU61lSZzedZG/EmkOWeYr1lmBGnXwnM91LWvympbYAlfm5Cj9/LIQU3kbWsgCM5mdTgCWa+e6QESjKOP+QUwXREp+rOeBcrtyAWP05vsGAzm7bpiTZaMWsEF82ztRUfnQHzjjsKiYwigLeJPPw2om0tIK5KkPo/X0WyVuCgYHanfvMDU6qiviRaprGD7evezg9xyFTrFNMgWEwGYCQGrs1IMzK6zbF5gQxVs6+4DGie/gIraoJ0ze5+s512WG18/FzKW/nwCMxT47l8VN1y3EjwhXFX1lvesjhHfBw== test.run-sandbox.aws.ext.govsvc.uk"

  concourse_main_password = "${var.concourse_password}"
}
