variable "zone" {
  type = "string"
  default = "govsvc.uk"
}

variable "name" {
  type = "string"
}

provider "aws" { }

provider "aws" {
  alias = "apex"
  region = "eu-west-2"
}

data "aws_route53_zone" "apex" {
  provider = "aws.apex"
  name = "${var.zone}"
}

resource "aws_route53_zone" "subdomain" {
  name = "verify.govsvc.uk"
}

resource "aws_route53_record" "ns" {
  provider = "aws.apex"
  zone_id = "${data.aws_route53_zone.apex.zone_id}"
  name    = "verify.govsvc.uk"
  type    = "NS"
  ttl     = "30"

  records = [
    "${aws_route53_zone.subdomain.name_servers.0}",
    "${aws_route53_zone.subdomain.name_servers.1}",
    "${aws_route53_zone.subdomain.name_servers.2}",
    "${aws_route53_zone.subdomain.name_servers.3}",
  ]
}

output "zone_id" {
  value = "${aws_route53_zone.subdomain.zone_id}"
}

output "name" {
  value = "${aws_route53_zone.subdomain.name}"
}
