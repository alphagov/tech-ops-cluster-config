terraform {
  backend "s3" {}
}

variable "aws_account_role_arn" {
  type = "string"
}

variable "splunk_hec_url" {
  type = "string"
}

variable "splunk_hec_token" {
  type = "string"
}

provider "aws" {
  region = "eu-west-2"
  assume_role {
    role_arn = "${var.aws_account_role_arn}"
  }
}

data "aws_caller_identity" "current" {}

module "gsp-cluster" {
    source = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-cluster"
    cluster_name = "staging"
    controller_count = 2
    controller_instance_type = "m5d.large"
    worker_count = 2
    worker_instance_type = "m5d.large"
    /* etcd_instance_type = "t3.medium" */
    dns_zone = "verify.govsvc.uk"
    user_data_bucket_name = "gds-verify-gsp-state"
    user_data_bucket_region = "eu-west-2"
    k8s_tag = "v1.12.2"
    admin_role_arns = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/admin",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/deployer",
    ]
    gds_external_cidrs = [
      "213.86.153.212/32",
      "213.86.153.213/32",
      "213.86.153.214/32",
      "213.86.153.235/32",
      "213.86.153.236/32",
      "213.86.153.237/32",
      "85.133.67.244/32",
      "18.130.144.30/32", # autom8 concourse
    ]
    splunk_hec_url = "${var.splunk_hec_url}"
    splunk_hec_token = "${var.splunk_hec_token}"
    addons = {
      ingress = 1
      canary = 0
      monitoring = 1
      secrets = 1
      ci = 0
      splunk = 1
    }
}

module "test-proxy-node" {
  source = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/flux-release"

  namespace      = "test-proxy-node"
  release_name   = "test" # Has to be changed later down the line.
  chart_git      = "https://github.com/alphagov/verify-eidas-deployment.git"
  chart_ref      = "master"
  chart_path     = "."
  cluster_name   = "${module.gsp-cluster.cluster-name}"
  cluster_domain = "${module.gsp-cluster.cluster-domain-suffix}"
  addons_dir     = "addons/${module.gsp-cluster.cluster-name}"
}

output "bootstrap-base-userdata-source" {
    value = "${module.gsp-cluster.bootstrap-base-userdata-source}"
}

output "bootstrap-base-userdata-verification" {
    value = "${module.gsp-cluster.bootstrap-base-userdata-verification}"
}

output "user-data-bucket-name" {
    value = "${module.gsp-cluster.user_data_bucket_name}"
}

output "user-data-bucket-region" {
    value = "${module.gsp-cluster.user_data_bucket_region}"
}

output "cluster-name" {
    value = "${module.gsp-cluster.cluster-name}"
}

output "controller-security-group-ids" {
    value = ["${module.gsp-cluster.controller-security-group-ids}"]
}

output "bootstrap-subnet-id" {
    value = "${module.gsp-cluster.bootstrap-subnet-id}"
}

output "controller-instance-profile-name" {
    value = "${module.gsp-cluster.controller-instance-profile-name}"
}

output "apiserver-lb-target-group-arn" {
    value = "${module.gsp-cluster.apiserver-lb-target-group-arn}"
}

output "dns-service-ip" {
    value = "${module.gsp-cluster.dns-service-ip}"
}

output "cluster-domain-suffix" {
    value = "${module.gsp-cluster.cluster-domain-suffix}"
}

output "k8s-tag" {
    value = "${module.gsp-cluster.k8s_tag}"
}

output "kubelet-kubeconfig" {
    value = "${module.gsp-cluster.kubelet-kubeconfig}"
    sensitive = true
}

output "admin-kubeconfig" {
    value = "${module.gsp-cluster.admin-kubeconfig}"
}

output "kube-ca-crt" {
    value = "${module.gsp-cluster.kube-ca-crt}"
}
