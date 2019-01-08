terraform {
  backend "s3" {
    bucket = "gds-re-run-sandbox-terraform-state"
    region = "eu-west-2"
    key    = "samcrang.run-sandbox.aws.ext.govsvc.uk/cluster.tfstate"
  }
}

data "aws_caller_identity" "current" {}

module "gsp-cluster" {
    source = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-cluster?ref=initial-import"
    cluster_name = "${var.cluster_name}"
    cluster_id = "samcrang.run-sandbox.aws.ext.govsvc.uk"
    dns_zone_id = "Z23SW7QP3LD4TS"
    dns_zone = "run-sandbox.aws.ext.govsvc.uk"
    ssh_authorized_keys = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDHtO59/mISjM3EzlKPn3A38IdiJfhGekrR+RLMc9/+AoTFGjmIZRKNDHRHhD4q5GJVEmB9QXxSt0sv4b5ufr3PEJR0DEZ9fKL038nVZyV6OEbSzolif04iFGPHycmRU4zErm5vJyN/FJTxptwkPWlgpyBx4ctFICqtBGAivRqCg3l59icEtOTo94Paz8cFidI1YTolj6hG2KbrZWGG4DGZ6O9CjcSkyYk3BJLxPGLPS8rW/zy1Fp3qXA4q1CCpYi4FQ7o1L8l8OOkBp0Uwq332ijO0pezOt4CyGqMdmITKQpQS2kE1nJpMi9A+Flu/T9ZrgrRgm8NVARlSYUc0QmnQObzMtwmmLhY3K6nesToQraikhnMqpHnmYhtuHH3JYGC7zeLR8RHZqqb7LCLZf4jmNDQbAtCHVgo5sQxw84dZKNKqWIbD1Jbkd9vOoNUM2I/TJQDtwVjzljlWdzIq68q3IKZBJS1x/n35vlyyNaEHSs3TdM0yYnKDukFqWbflzwm7Zl+X1NsuRSAdmShc4jzDGreUm9fRUTY+vtTjbIyo+Sv4nmVmWEjV9NH/DL93m9yKn10ZOOgEp/OFGE/nvapV2v+jz96plC0GCKUgJ/KxFqbxfW6T596bODsqr66553Q+ZjT/yBHzN7tO3T4SXRdn/qQvPkP+yAg76wtPwiFspQ== sam.crang@digital.cabinet-office.gov.uk GPG:B91590AEA3A6B81BCAE99ADC1F07315057BC3A55"]
    user_data_bucket_name = "${var.user_data_bucket_name}"
    user_data_bucket_region = "${var.user_data_bucket_region}"
    k8s_tag = "${var.k8s_tag}"
    admin_role_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/admin"]
}

module "gsp-base-release" {
  source = "../../modules/github-flux"

  namespace      = "gsp-base"
  chart_git      = "https://github.com/alphagov/gsp-base.git"
  chart_ref      = "master"
  chart_path     = "charts/base"
  cluster_name   = "${var.cluster_name}"
  cluster_domain = "samcrang.run-sandbox.aws.ext.govsvc.uk"
}

module "gsp-monitoring-release" {
  source = "../../modules/github-flux"

  namespace      = "monitoring-system"
  chart_git      = "https://github.com/alphagov/gsp-monitoring.git"
  chart_ref      = "master"
  chart_path     = "monitoring"
  cluster_name   = "${var.cluster_name}"
  cluster_domain = "samcrang.run-sandbox.aws.ext.govsvc.uk"
}

module "gsp-canary" {
  source     = "../../modules/canary"
  cluster_id = "samcrang.run-sandbox.aws.ext.govsvc.uk"
}

module "gsp-sealed-secrets" {
  source = "../../modules/github-flux"

  namespace      = "secrets-system"
  chart_git      = "https://github.com/alphagov/gsp-sealed-secrets.git"
  chart_ref      = "master"
  chart_path     = "charts/sealed-secrets"
  cluster_name   = "${var.cluster_name}"
  cluster_domain = "samcrang.run-sandbox.aws.ext.govsvc.uk"
}

module "gsp-ci-system" {
  source = "../../modules/github-flux"

  namespace      = "ci-system"
  chart_git      = "https://github.com/alphagov/gsp-ci-system.git"
  chart_ref      = "add-notary"
  chart_path     = "charts/ci"
  cluster_name   = "${var.cluster_name}"
  cluster_domain = "samcrang.run-sandbox.aws.ext.govsvc.uk"
}

module "gsp-concourse-ci-pipelines" {
  source = "../../modules/github-flux"

  namespace      = "${module.gsp-ci-system.release-name}-main"
  chart_git      = "https://github.com/alphagov/gsp-ci-pipelines.git"
  chart_ref      = "master"
  chart_path     = "charts/pipelines"
  cluster_name   = "${var.cluster_name}"
  cluster_domain = "samcrang.run-sandbox.aws.ext.govsvc.uk"
  values = <<HEREDOC
    ecr:
      registry: ${data.aws_caller_identity.current.account_id}.dkr.ecr.eu-west-2.amazonaws.com
      region: eu-west-2
HEREDOC
}
