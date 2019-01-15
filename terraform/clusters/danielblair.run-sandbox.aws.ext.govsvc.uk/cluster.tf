terraform {
  backend "s3" {
    bucket = "gds-re-run-sandbox-terraform-state"
    region = "eu-west-2"
    key    = "danielblair.run-sandbox.aws.ext.govsvc.uk/cluster.tfstate"
  }
}

data "aws_caller_identity" "current" {}

module "gsp-network" {
  source       = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-network?ref=eks-firebreak"
  cluster_name = "danielblair"
}

module "gsp-persistent" {
  source       = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-persistent?ref=eks-firebreak"
  cluster_name = "${module.gsp-network.cluster-name}"
  dns_zone     = "run-sandbox.aws.ext.govsandbox.uk"
}

module "gsp-cluster" {
  source               = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-cluster?ref=eks-firebreak"
  cluster_name         = "danielblair"
  dns_zone             = "run-sandbox.aws.ext.govsandbox.uk"
  admin_role_arns      = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/admin"]
  worker_instance_type = "m5.large"
  worker_count         = "2"

  addons = {
    ci = 1
  }

  sealed_secrets_cert_pem        = "${module.gsp-persistent.sealed_secrets_cert_pem}"
  sealed_secrets_private_key_pem = "${module.gsp-persistent.sealed_secrets_private_key_pem}"
  vpc_id                         = "${module.gsp-network.vpc_id}"
  private_subnet_ids             = "${module.gsp-network.private_subnet_ids}"
  public_subnet_ids              = "${module.gsp-network.public_subnet_ids}"
  nat_gateway_public_ips         = "${module.gsp-network.nat_gateway_public_ips}"

  sre_user_arns = ["arn:aws:iam::622626885786:user/daniel.blair@digital.cabinet-office.gov.uk"]
  github_client_id = ""
  github_client_secret = ""
}

module "prototype-kit" {
  source = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/flux-release?ref=eks-firebreak"

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

output "kubeconfig" {
  value = "${module.gsp-cluster.kubeconfig}"
}
