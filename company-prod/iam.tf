/* 
Start: Organization Administrators permissions
*/
resource "aws_iam_role" "company-users-organization-administrators" {
    name = "company-users-organization-administrators"
    path = "/"
    description = "A role to delegate access for organization-administrators in the company-users AWS account to the company-prod AWS account."
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Principal": {
        "AWS": "arn:aws:iam::222222222222:root"
        },
        "Effect": "Allow"
    }
    ]
}
EOF
} 


resource "aws_iam_role_policy_attachment" "company-users-organization-administrators-aws-policy-attachment" {
    role       = "${aws_iam_role.company-users-organization-administrators.name}"
    policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
/* 
End: Organization Administrators  permissions
*/

/* 
Start: Developer permissions
*/
resource "aws_iam_role" "company-users-developers" {
    name = "company-users-developers"
    path = "/"
    description = "A role to delegate access for developers in the company-users AWS account to the company-prod AWS account."
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Principal": {
        "AWS": "arn:aws:iam::222222222222:root"
        },
        "Effect": "Allow"
    }
    ]
}
EOF
}    

resource "aws_iam_role_policy_attachment" "company-users-developers-ec2-policy-attachment" {
    role       = "${aws_iam_role.company-users-developers.name}"
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}
resource "aws_iam_role_policy_attachment" "company-users-developers-s3-policy-attachment" {
    role       = "${aws_iam_role.company-users-developers.name}"
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
resource "aws_iam_role_policy_attachment" "company-users-developers-ecs-policy-attachment" {
    role       = "${aws_iam_role.company-users-developers.name}"
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}
resource "aws_iam_role_policy_attachment" "company-users-developers-sqs-policy-attachment" {
    role       = "${aws_iam_role.company-users-developers.name}"
    policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

/* 
End: Developer permissions
*/