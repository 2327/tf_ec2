terraform {
  required_version = ">= 0.12"
  #  backend "s3" {}
}

provider "aws" {
  region  = var.aws-region
  profile = "2327"
}

#locals {
#  state-config = {
#  #  bucket = var.s3_bucket
#    region = var.region
#  }
#}
#
