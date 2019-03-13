terraform {
  backend "s3" {
    bucket = "gds-re-run-sandbox-terraform-state"
    region = "eu-west-2"
    key    = "davidmcdonald.run-sandbox.aws.ext.govsvc.uk/persistent.tfstate"
  }
}

provider "aws" {
  region = "eu-west-2"
}
