# Lookup VPC by the "company:environment" tag. Here we substring 'company-test' to get the environment name 'test', the expected value of the tag on the company VPC for this region
data "aws_vpc" "company-vpc" {
  tags {
    "company:environment" = "${substr(var.account-name, 8, -1)}"
  }
}
# Get all private subnets for the selected VPC
data "aws_subnet_ids" "matched-subnets" {
  vpc_id = "${data.aws_vpc.company-vpc.id}"
  tags {
    "company:isPublic" = "false"
  }
}

data "aws_security_group" "ecs-instance-security-group" {
    name = "ecs-${var.ecs-cluster-number}-instance-security-group"
}

data "aws_security_group" "ec2-linux-bastion-security-group" {
    name = "ec2-linux-bastion-security-group"
}

/* 
START: Security Group
*/
resource "aws_security_group" "ec2-rds-instance-security-group" {
  description = "Controls access to the ec2-rds-${var.rds-instance-number} RDS instance"
  vpc_id = "${data.aws_vpc.company-vpc.id}"
  name   = "ec2-rds-${var.rds-instance-number}-instance-security-group"

  ingress {
    description = "ECS instance RDS PostgreSQL access"
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    security_groups = ["${data.aws_security_group.ecs-instance-security-group.id}"]
  }

  ingress {
    description = "Bastion instance RDS PostgreSQL access"
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    security_groups = ["${data.aws_security_group.ec2-linux-bastion-security-group.id}"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
}
/* 
END: Security Group
*/

/* 
START: PostgreSQL Database configuration
*/
resource "random_string" "password" {
  length = 16
  special = false
}

locals {
  username = "companydbmaster"
  database-name = "company_engine_db"
  port = "5432"  
}

module "db" {
  source = "terraform-aws-modules/rds/aws"
  identifier = "company-test-eu-west-2-${var.rds-instance-number}"
  engine            = "postgres"
  engine_version    = "9.6.3"
  instance_class    = "db.t2.small"
  allocated_storage = 30
  storage_encrypted = false
  snapshot_identifier = "arn:aws:rds:eu-west-2:111111111111:snapshot:company-test-final-snapshot-90bc8371fd1d1d77c19398acf466b099"
  # kms_key_id        = "arm:aws:kms:<region>:<accound id>:key/<kms key id>"
  name = "${local.database-name}"
  username = "${local.username}"
  password = "${random_string.password.result}"
  port     = "${local.port}"
  vpc_security_group_ids = ["${aws_security_group.ec2-rds-instance-security-group.id}"]
  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"
  # disable backups to create DB faster
  backup_retention_period = 0
  tags = {
    "company:environment" = "${substr(var.account-name, 8, -1)}"
  }
  subnet_ids = ["${data.aws_subnet_ids.matched-subnets.ids}"]
  family = "postgres9.6"
  skip_final_snapshot = "false"
  final_snapshot_identifier = "${var.account-name}-final-snapshot-${md5(timestamp())}"
}

/* 
END: PostgreSQL Database configuration
*/

/* 
START: Publish RDS PostgreSQL connection string to AWS EC2 Parameter Store
*/
resource "aws_ssm_parameter" "connection-string" {
  name  = "/database/rds/${var.rds-instance-number}/connection-string/${local.username}"
  type  = "SecureString"
  value = "postgres://${local.username}:${random_string.password.result}@${module.db.this_db_instance_endpoint}/${local.database-name}"
}

/* 
END: Publish RDS POstgreSQL connection string to AWS EC2 Parameter Store
*/