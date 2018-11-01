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

variable "concourse_main_password" {
    type = "string"
}

module "cluster" {
  source = "git::https://github.com/alphagov/gsp-typhoon//aws/container-linux/kubernetes?ref=v1.12.2"

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
        main_password = "${var.concourse_main_password}"
    }
}

resource "local_file" "values_yaml" {
    filename = "values.yaml"
    content = "${data.template_file.values_yaml.rendered}"

    provisioner "local-exec" {
        command = "../../../scripts/render.sh"
    }
}
