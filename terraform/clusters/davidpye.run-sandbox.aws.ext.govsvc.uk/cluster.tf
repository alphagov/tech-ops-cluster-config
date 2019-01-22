terraform {
  backend "s3" {
    bucket = "gds-re-run-sandbox-terraform-state"
    region = "eu-west-2"
    key    = "davidpye.run-sandbox.aws.ext.govsandbox.uk/cluster.tfstate"
  }
}

data "aws_caller_identity" "current" {}

module "gsp-cluster" {
    source = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-cluster?ref=dev-role"
    cluster_name = "davidpye"
    dns_zone = "run-sandbox.aws.ext.govsandbox.uk"
    user_data_bucket_name = "gds-re-run-sandbox-terraform-state"
    user_data_bucket_region = "eu-west-2"
    k8s_tag = "v1.12.2"
    admin_role_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/admin"]

    addons = {
      ingress = 1
      monitoring = 1
      secrets = 1
      ci = 1
      splunk = 0
    }

    dev_user_arns = [
      "arn:aws:iam::622626885786:user/daniel.blair@digital.cabinet-office.gov.uk",
      "arn:aws:iam::622626885786:user/david.pye@digital.cabinet-office.gov.uk",
    ]
    dev_namespaces = ["kube-system", "flux-system"]
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
