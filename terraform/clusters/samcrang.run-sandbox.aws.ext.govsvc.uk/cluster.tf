terraform {
  backend "s3" {
    bucket = "gds-re-run-sandbox-terraform-state"
    region = "eu-west-2"
    key    = "samcrang.run-sandbox.aws.ext.govsvc.uk/cluster.tfstate"
  }
}

data "aws_caller_identity" "current" {}

module "gsp-cluster" {
    source = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-cluster"
    cluster_name = "samcrang"
    dns_zone = "run-sandbox.aws.ext.govsandbox.uk"
    user_data_bucket_name = "gds-re-run-sandbox-terraform-state"
    user_data_bucket_region = "eu-west-2"
    k8s_tag = "v1.12.2"
    admin_role_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/admin"]
    controller_instance_type = "m5d.large"
    worker_instance_type = "m5d.large"

    addons = {
      ingress = 1
      canary = 0
      monitoring = 1
      secrets = 1
      ci = 1
    }
}

module "main-pipelines" {
  source = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/flux-release"

  namespace      = "${module.gsp-cluster.ci-system-release-name}-main"
  chart_git      = "https://github.com/alphagov/verify-eidas-pipelines.git"
  chart_ref      = "develop"
  chart_path     = "."
  cluster_name   = "${module.gsp-cluster.cluster-name}"
  cluster_domain = "${module.gsp-cluster.cluster-domain-suffix}"
  addons_dir     = "addons/${module.gsp-cluster.cluster-name}"
  values = <<HEREDOC
    harbor:
      keys:
        ci: "${module.gsp-cluster.notary-ci-private-key}"
        root: "${module.gsp-cluster.notary-root-private-key}"
      passphrase:
        delegation: "${module.gsp-cluster.notary-delegation-passphrase}"
        root: "${module.gsp-cluster.notary-root-passphrase}"
        snapshot: "${module.gsp-cluster.notary-snapshot-passphrase}"
        targets: "${module.gsp-cluster.notary-targets-passphrase}"
      password: "${module.gsp-cluster.harbor-password}"
HEREDOC
}

module "prototype-kit" {
  source = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/flux-release"

  namespace      = "gsp-prototype-kit"
  chart_git      = "https://github.com/alphagov/gsp-govuk-prototype-kit.git"
  chart_ref      = "gsp"
  chart_path     = "charts/govuk-prototype-kit"
  cluster_name   = "${module.gsp-cluster.cluster-name}"
  cluster_domain = "${module.gsp-cluster.cluster-domain-suffix}"
  addons_dir     = "addons/${module.gsp-cluster.cluster-name}"
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
