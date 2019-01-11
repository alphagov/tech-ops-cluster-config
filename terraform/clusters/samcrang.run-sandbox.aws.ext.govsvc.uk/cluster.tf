terraform {
  backend "s3" {
    bucket = "gds-re-run-sandbox-terraform-state"
    region = "eu-west-2"
    key    = "samcrang.run-sandbox.aws.ext.govsvc.uk/cluster.tfstate"
  }
}

data "aws_caller_identity" "current" {}

data "aws_route53_zone" "zone" {
  name = "${var.cluster_zone}."
}

module "gsp-cluster" {
    source = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-cluster"
    cluster_name = "${var.cluster_name}"
    cluster_id = "${var.cluster_name}.${var.cluster_zone}"
    dns_zone_id = "${data.aws_route53_zone.zone.zone_id}"
    dns_zone = "${var.cluster_zone}"
    user_data_bucket_name = "${var.user_data_bucket_name}"
    user_data_bucket_region = "${var.user_data_bucket_region}"
    k8s_tag = "${var.k8s_tag}"
    admin_role_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/admin"]
}

module "gsp-base-release" {
  source = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/flux-release"

  namespace      = "gsp-base"
  chart_git      = "https://github.com/alphagov/gsp-base.git"
  chart_ref      = "master"
  chart_path     = "charts/base"
  cluster_name   = "${var.cluster_name}"
  cluster_domain = "${var.cluster_name}.${var.cluster_zone}"
}

module "gsp-monitoring-release" {
  source = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/flux-release"

  namespace      = "monitoring-system"
  chart_git      = "https://github.com/alphagov/gsp-monitoring.git"
  chart_ref      = "master"
  chart_path     = "monitoring"
  cluster_name   = "${var.cluster_name}"
  cluster_domain = "${var.cluster_name}.${var.cluster_zone}"
}

module "gsp-canary" {
  source     = "../../modules/canary"
  cluster_id = "${var.cluster_zone}"
}

module "gsp-sealed-secrets" {
  source = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/flux-release"

  namespace      = "secrets-system"
  chart_git      = "https://github.com/alphagov/gsp-sealed-secrets.git"
  chart_ref      = "master"
  chart_path     = "charts/sealed-secrets"
  cluster_name   = "${var.cluster_name}"
  cluster_domain = "${var.cluster_name}.${var.cluster_zone}"
}

module "gsp-ci-system" {
  source = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/flux-release"

  namespace      = "ci-system"
  chart_git      = "https://github.com/alphagov/gsp-ci-system.git"
  chart_ref      = "add-notary"
  chart_path     = "charts/ci"
  cluster_name   = "${var.cluster_name}"
  cluster_domain = "${var.cluster_name}.${var.cluster_zone}"
}

module "gsp-concourse-ci-pipelines" {
  source = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/flux-release"

  namespace      = "${module.gsp-ci-system.release-name}-main"
  chart_git      = "https://github.com/alphagov/gsp-ci-pipelines.git"
  chart_ref      = "master"
  chart_path     = "charts/pipelines"
  cluster_name   = "${var.cluster_name}"
  cluster_domain = "${var.cluster_name}.${var.cluster_zone}"
  values = <<HEREDOC
    ecr:
      registry: ${data.aws_caller_identity.current.account_id}.dkr.ecr.eu-west-2.amazonaws.com
      region: eu-west-2
HEREDOC
}

module "gsp-prototype-kit" {
  source = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/flux-release"

  namespace      = "gsp-prototype-kit"
  chart_git      = "https://github.com/alphagov/gsp-govuk-prototype-kit.git"
  chart_ref      = "gsp"
  chart_path     = "charts/govuk-prototype-kit"
  cluster_name   = "${var.cluster_name}"
  cluster_domain = "${module.gsp-cluster.cluster-domain-suffix}"
  values = <<EOF
    ingress:
      hosts:
        - pk.${module.gsp-cluster.cluster-domain-suffix}
        - prototype-kit.${module.gsp-cluster.cluster-domain-suffix}
      tls:
        - secretName: prototype-kit-tls
          hosts:
            - pk.${module.gsp-cluster.cluster-domain-suffix}
            - prototype-kit.${module.gsp-cluster.cluster-domain-suffix}
EOF
}
