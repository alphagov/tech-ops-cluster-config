variable "allowed_ips" {
  type = "list"

  default = [
    "85.133.67.244/32",
    "213.86.153.212/32",
    "213.86.153.213/32",
    "213.86.153.214/32",
    "213.86.153.235/32",
    "213.86.153.236/32",
    "213.86.153.237/32",
  ]
}

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

variable "codecommit_url" {
  type = "string"
}

variable "admin_role_arns" {
  type = "list"
}

module "cluster" {
  source = "git::https://github.com/alphagov/gsp-typhoon//aws/container-linux/kubernetes?ref=restrict-api-access-2"

  # AWS
  cluster_name = "${var.cluster_name}"
  dns_zone     = "${var.zone_name}"
  dns_zone_id  = "${var.zone_id}"

  # configuration
  ssh_authorized_key = "${var.ssh_authorized_key}"
  asset_dir          = "bootkube-assets"

  # optional
  allowed_ips  = ["${var.allowed_ips}"]
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

data "template_file" "values_yaml" {
  template = "${file("${path.module}/data/values.yaml")}"

  vars {
    cluster_domain = "${var.cluster_name}.${var.zone_name}"
    main_username  = "admin"
    main_password  = "password"
  }
}

resource "local_file" "values_yaml" {
  filename = "values.yaml"
  content  = "${data.template_file.values_yaml.rendered}"

  provisioner "local-exec" {
    command = "../../../scripts/render.sh \"${var.codecommit_url}\""
  }
}
