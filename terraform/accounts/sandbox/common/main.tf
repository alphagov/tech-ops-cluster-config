terraform {
  backend "s3" {}
}

provider "aws" {
  region = "eu-west-2"
  assume_role {
    role_arn = "${var.aws_account_role_arn}"
  }
}

module "domain" {
  source = "../../../modules/subdomain"
  zone = "govsvc.uk"
  name = "${var.account_name}"
  providers = { aws = "aws" }
}

module "gsp-network" {
  source       = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-network?ref=eks-firebreak"
  cluster_name = "${var.cluster_name}"
}

module "gsp-persistent" {
  source       = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-persistent?ref=eks-firebreak"
  cluster_name = "${module.gsp-network.cluster-name}"
  dns_zone     = "${module.domain.name}"
}


// FIXME: find me a home -- pre bootstrap - one off - humans?
/* data "aws_iam_policy_document" "deployer" { */
/*   statement { */
/*     effect  = "Allow" */
/*     actions = ["sts:AssumeRole"] */

/*     principals = { */
/*       type = "AWS" */

/*       identifiers = ["arn:aws:iam::047969882937:role/cd-gsp-concourse-worker"] */
/*     } */
/*   } */
/* } */

/* resource "aws_iam_role" "deployer" { */
/*   name = "deployer" */

/*   assume_role_policy = "${data.aws_iam_policy_document.deployer.json}" */
/* } */

/* resource "aws_iam_role_policy_attachment" "deployer" { */
/*   role       = "${aws_iam_role.deployer.name}" */
/*   policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" */
/* } */
