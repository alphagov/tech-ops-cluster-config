terraform {
  backend "s3" {}
}

variable "aws_account_role_arn" {
  description = "ARN of the role in which this is being run"
  type        = "string"
}

provider "aws" {
  region = "eu-west-2"

  assume_role {
    role_arn = "${var.aws_account_role_arn}"
  }
}
