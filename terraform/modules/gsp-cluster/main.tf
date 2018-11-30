variable "cluster_name" {
  type = "string"
}

variable "zone_name" {
  type = "string"
}

variable "zone_id" {
  type = "string"
}

variable "ssh_authorized_key" {
  type = "string"
}

variable "admin_role_arns" {
  type = "list"
}

module "cluster" {
  source = "git::https://github.com/alphagov/gsp-typhoon//aws/container-linux/kubernetes?ref=flux-spike"

  # AWS
  cluster_name = "${var.cluster_name}"
  dns_zone     = "${var.zone_name}"
  dns_zone_id  = "${var.zone_id}"

  # configuration
  ssh_authorized_key = "${var.ssh_authorized_key}"
  asset_dir          = "bootkube-assets"

  # optional
  worker_count = 2
  worker_type  = "t2.medium"

  cluster_id = "${var.cluster_name}.${var.zone_name}"
  admin_role_arns = "${var.admin_role_arns}"
}

# needed until externalDNS starts to work
resource "aws_route53_record" "ingress" {
  zone_id = "${var.zone_id}"
  name    = "*.${var.cluster_name}.${var.zone_name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${module.cluster.ingress_dns_name}"]
}

