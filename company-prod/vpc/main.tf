module "vpc" {
    source = "git@github.com:stackingup/aws-level-up-architecture-modules.git//vpc//region-eu-west-2?ref=v1.0.0"
    region = "${var.region}"
    account-name = "${var.account-name}"
    vpc-cidr-block = "${var.vpc-cidr-block}"
    default-tags = {
        "company:environment" = "${substr(var.account-name, 8, -1)}"
    }
    eu-west-2a-nat-gateway-eip-alloc-id = "eipalloc-11111111"
    eu-west-2b-nat-gateway-eip-alloc-id = "eipalloc-22222222"
}