terraform {
  required_version = ">= 0.10.6"  
  backend "s3" {
    bucket = "company-ops-terraform-s3s-versioned-0001"
    key    = "company-test/database/rds/terraform.tfstate"
    region = "eu-west-2"
    profile = "company-users-AppTerraform"
  }
}

provider "aws" {
  region = "${var.region}"
  profile = "company-test-AppTerraform"
  allowed_account_ids = ["${var.account-company-test}"]
}