provider "aws" {
    region = "${var.region}"
    profile = "company-ops-AppTerraform"
    allowed_account_ids = ["${var.account-company-ops}"]
}

resource "aws_s3_bucket" "terraform-state" {
    bucket  = "company-ops-terraform-s3s-versioned-0001"
    acl     = "private" 
    region  = "${var.region}"
    versioning {
        enabled = true
    }
    lifecycle {
        prevent_destroy = true
    }
}