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
    key    = "rafalp.run-sandbox.aws.ext.govsvc.uk/cluster.tfstate"
  }
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
  cluster_name = "rafalp"
  zone_name    = "run-sandbox.aws.ext.govsvc.uk"
  zone_id      = "Z23SW7QP3LD4TS"

  # configuration
  ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDm1xKMnwydS4TNtmEhCei6O9Zvxn7wVgkfhe6/nCfie/Ba82x52AAsMWONpuv54Acb6fcSeBAYpv68+3a94eg5fGDj39NvN5NBiPzl/OjwhANfX+P+8ax2eqNz9nBWJPpSAbu1fagTOqLQMqcsKwljJWhM2fGmG7jQMF806BEssCDtVcmF8MRjckhEnhOdKaiqbWYFHQXVAzgzgEQnaKkAq0H4IllopIOba431WlG1TFySnzUWI5k3Ep7He96L3J6dnt2lh0NfoGp1Kb05UEe71nBMS0okC1Rk1zDm7upNonVvBmo4S+1Aw8W+PEu16EH8h8kgfH0gPIqM1y1tYwibm8f8YkMyATA7fIQfmDMujborDRwi3JUI2d0I+nQTfT4xUfZEmh/PvHjegxvZ/dlp+up8fKVAY0ZSawTPhUapuBZaFn3kUjZbT6qSynlSObo6CqhHgPbkWkbIboXEhhYjx/Pgkm0E+vTI3Aq4amr8RXCH9J6/OmnZcTkGRIbC2rvY6W4OeqsrgGE9peB811YT5qfKx7eUNHGryS8hw0nNbLq7cRrfeMca9ddfH4YtQE0tX/IdYgMs1x89+yO4Pj8FsuCjQp7DFlzWKZgGPc+gnoYZz4aNeK3jBrvWF3HAQrCFkL04CjJJvhcGApfNgh42RoADqJOEyqGTH++radeAeQ== rafalp.run-sandbox.aws.ext.govsvc.uk"

  concourse_main_password = "${var.concourse_password}"

  codecommit_url = "${module.gsp-base-applier.repo_url}"
}

module "gsp-base-applier" {
  source = "../../modules/codecommit-kube-applier"

  repository_name        = "rafalp.run-sandbox.aws.ext.govsvc.uk.gsp-base"
  repository_description = "State of the gsp-base world!"
  namespace              = "gsp-base"
}

module "design-applier" {
  source = "../../modules/codecommit-kube-applier"

  repository_name        = "rafalp.run-sandbox.aws.ext.govsvc.uk.gsp-design"
  repository_description = "Node application we'd like to apply to the design namespace."
  namespace              = "design"
}

module "observe-applier" {
  source = "../../modules/codecommit-kube-applier"

  repository_name        = "rafalp.run-sandbox.aws.ext.govsvc.uk.gsp-observe"
  repository_description = "Node application we'd like to apply to the observe namespace."
  namespace              = "observe"
}
