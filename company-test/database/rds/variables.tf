variable "region" {
  description = "The AWS region to target deployment to"
  default = "eu-west-2"
}

variable "account-company-test" {
  description = "The alias name of the AWS company-test account"
  default = "111111111111"
}

variable "account-name" {
  description = "The name of the AWS account calling the module"
  default = "company-test"
}

variable "rds-instance-number" {
  description = "The suffix to add to RDS instance name, e.g. 0001"
}

variable "ecs-cluster-number" {
  description = "The ECS cluster to allow connections from, e.g. 0001"
}

variable "admin-cidr-ingress" {
  description = "CIDR address range to allow SSH (tcp/22) connectivity to ECS cluster instances"
  default     = "127.0.0.1/32"
}