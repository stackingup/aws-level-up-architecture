# aws-level-up-architecture
Defines Infrastructure as Code (IaC) Terraform configuration for the AWS StackingUp Level-Up Architecture.

# Deployment 


# AWS accounts
## company-users
The primary AWS account for defining users and their access control via groups and policies. Users will use delegated temporary short-term credentials to assume the least privilege access to other Company AWS accounts.

# AWS authentication
A few notes on authentication to AWS, this becomes tricky as we are targetting multiple AWS accounts....plus we don't want to accidently share secrets, be aware this is WIP and likely to change!

## Create a single IAM user using the AWS console
*This step is only required when standing up the AWS infrastructre for the first time or if the company-users AWS account is trashed!* 

* Login to the AWS Console https://console.aws.amazon.com using the root credentials for the company-users account
* Select 'Services>IAM>Users>Add user'
* Set 'User name*' = 'AppTerraform'
* Under 'Access type*' Check 'Programmatic access' only
* Select 'Next: Permissions'
* Select 'Attach existing policies directly'
* Check 'AdministratorAccess'
* Select 'Next: Review'  
* Select 'Create user'
* Select 'Download .csv' to download the Access Key credentials.

## Configure an AWS credentials profile for the company-users AWS account
Note: The Access Key IDs and Access Keys *must* be from the AppTerraform IAM user 

```
$ aws configure --profile company-users-AppTerraform
AWS Access Key ID [None]: KEYID_FROM_APPTERRAFORM_USER
AWS Secret Access Key [None]: KEY_FROM_APPTERRAFORM_USER
Default region name [None]: eu-west-2
Default output format [None]: json
```

The above will generate an `[AppTerraform]` section in the AWS credentials file located at `~/.aws/credentials` on Linux, macOS, or Unix, or at `C:\Users\USERNAME\.aws\credentials` on Windows.

# Terraform
Terraform is a tool that enables Infrastructure as Code (IaC). Infrastructure configuration is defined in templates (*.tf files), applied via the Terraform cross-platform CLI, with state of applied infrastructure centrally stored within an AWS S3 bucket, the S3 bucket is referred to as a Terraform 'backend'. 

## One-time only configuration
To configure the Terraform backend to store the state of the Company infrastructure, it is necessary to provision an S3 bucket within AWS. Here we have a chicken-and-egg situation, as we want to use Terraform to configure our infrastructure, which includes all S3 buckets, but we don't have an S3 bucket provisioned for Terraform to write to, meaning Terraform errors out!
The simple solution for this single S3 bucket, which is a one-time configuration only, is to use the Terraform local backend, this stores the infrastructure state for this bucket within this repository as a local `terraform.tfstate` file, therefore running: 

```
cd terraform-backend
$\terraform-backend> terraform init
$\terraform-backend> terraform apply
```

results in:

* the S3 bucket `company-users-terraform-s3s-versioned-0001` being provisioned within our target AWS account (company-users)
* the Terraform state being created under ` .\terraform-backend\terraform.tfstate`

## Continuous configuration

### Identity & Access Management (IAM) configuration

```
cd company-users
$\company-users> terraform init
$\tcompany-users> terraform apply
```

### All other service resource configuration

# Conventions

## AWS Tagging Model
Tagging resources in AWS is useful for cost reporting, to categorise and attribute the cost of services, and security, to restrict access by tag(s). The following table defines a initial list of tags and how they can be used within AWS for the Company infrastructure.

|Key Name|Mandatory?|Data type/Allowed Value|Case|Notes|
| --- | --- | --- | --- | --- |
|Name|Mandatory for all resources|Differes by resource. Based on a collection of other tags|kebab-case| Name of resource|
|Company:environment|Mandatory for all resources|String. Predefined set of environments|camelCase|Defines the Company environment, e.g. devLloyd, staging, prod1, prod2|
|Company:environmentId|Mandatory for all resources|integer|-|Defines the environment number, e.g.|
|Company:application|Mandatory for all resources|String. Predefined set of services|camelCase|Defines the Company service, e.g. engine, dashboard, stm|
|Company:buildId|Optional|integer|-|Holds the buildId from the terraform repo|
|Company:owner|Mandatory for all resources|(email)|-|An email address. For production environments this *should not* be a single person|
|Company:taggingVersion|Mandatory for all resources|1|-|Holds the version of this tagging format. |


## AWS Resource Naming Conventions

|AWS Service|Resource Type|Conventions|Example|Notes|
| --- | --- | --- | --- | --- |
|IAM|User (person)|(PascalCase)FirstName then Surname|LloydHolman JohnSmith||
|IAM|User (application)|(PascalCase)'App' followed by the internal application name	AppEngine AppStm|Optionally add a verb to the application user name if multiple, more granular user accounts can be used, e.g. AppRedtailWrite.|
|IAM|Group|(kebab-case)A noun (or AWS Organization or AWS Account or AWS Service name) describing the area of access followed by a collective noun describing the level of user access.|account-developers company-users-administrators billing-viewers billing-administrators|Where possible I ensure the first noun matches the language used within AWS, i.e. account-administrators, not system-administrators.
|IAM|Role|(kebab-case)The trusted entity (AWS service or other AWS account name) followed by the application name, followed by a summary of the combined policies access|ec2-apppricingapi-readonly cloudfront-appimageconverter-writelogs|An instance can only be associated to 1 role. 1 role can be attached to a maximum of 10 policies. Maximum of 64 characters. I haven't tested these conventions with roles used to permission users using the Web Identity or SAML providers.|
|IAM|Policy|(kebab-case) AWS Account name followed by AWS service name (optionally followed by target service name for e.g. with replication) followed by summary of access level actions|myorg-billing-fullaccess myorg-billing-viewaccess|The organisation name (or account name) should ideally match that used when defining your resource tagging.|
|S3|Bucket|(kebab-case)AWS Account name followed by the internal application name, followed by an intended Storage Class Identifier (sci), followed by an optional 'versioned' string if the bucket is to have versioning enabled, followed by a 4 digit integer|company-production-engine-sia-0076 company-test-stm-versioned-s3s-0009|S3 bucket names must be unique across the AWS infrastructre. There is no need to include the AWS region in the name as that is included in the bucket uri |
|SQS|Queue|(kebab-case)AWS Account name followed by the internal application name and/or purpose. Followed by a mandatory .fifo suffix if it is a FIFO queue|company-test-vam-journey-detail company-prod-vam-alerts|SQS queue names must be unique across an AWS accounts infrastructure, however we're including the account name to avoid ambiguity|

# Visualizing Terraform changes

In Windows
```
$ terraform graph -type=plan | Export-PSGraph
```

*nix
```
$ terraform graph | dot -Tpng > graph.png
```

# Networking

## Virtual Private Clouds (VPC)
A VPC is a software-defined network (SDN) optimized for moving massive amounts of packets into, out of and across AWS regions.
A VPC is specific to an AWS region but can span all Availability Zones (AZ) within a region
A VPC can route to all other hosts within a VPC. Period.

## Subnets 
Proper subnet layout is the key to a well-functioning VPC. Subnets determine routing, Availability Zone (AZ) distribution, and Network Access Control Lists (NACLs). We will not unecessarily split the VPC in to many subnets.

## Our Approach
The following is the approach used for the Company infrastructure

* Each VPC will use a 16-bit net mask, giving 65534 available IP addresses
* We will use the RFC198 `10.0.0.0 - 10.255.255.255` recommended private address range
* Each region will have one VPC
* Where possible we will use every Availability Zone (AZ)
* We will configure the network exactly the same in every AZ
* Routing and security will define subnets. We will not unecessarily split the VPC in to many subnets
* We will Keep the number of routing tables to an absolute minimum
* We will always leave spare capacity

Reference: https://medium.com/aws-activate-startup-blog/practical-vpc-design-8412e1a18dcc

## Example
The below example is based on the `company-test` AWS account, using a VPC CIDR block of `10.20.0.0/16` 

* A single VPC with CIDR block `10.20.0.0/16`
* A private subnet using a /19 net mask (8190 IP addresses) in each of the two availability zones (AZ), `eu-west-2a` and `eu-west-2b`
    * `10.20.0.0/19-eu-west-2a-private`
    * `10.20.64.0/19-eu-west-2b-private`
* A further smaller public subnet using a /20 net mask (4094 IP addresses) in each of the two AZs, `eu-west-2a` and `eu-west-2b`
    * `10.20.32.0/20-eu-west-2a-public`
    * `10.20.96.0/20-eu-west-2b-public`

The network topology for the eu-west-2 (London) `company-test` AWS account then resembles the following:

```
10.20.0.0/16 - VPC (company-test-eu-west-2)
    10.20.0.0/18 - eu-west-2a
        10.20.0.0/19 - private subnet (10.20.0.0/19-eu-west-2a-private)
        10.20.32.0/19
               10.20.32.0/20 - public subnet (10.20.32.0/20-eu-west-2a-public)
               10.20.48.0/20 - spare
    10.20.64.0/18 - eu-west-2b
        10.20.64.0/19 - private subnet (10.20.64.0/19-eu-west-2b-private)
        10.20.96.0/19
                10.20.96.0/20 - public subnet (10.20.96.0/20-eu-west-2b-public)
                10.20.112.0/20- spare
    10.20.128.0/18 - spare
    10.20.192.0/18 - spare
```

* The /18 spare CIDR blocks provide support for additional AZs (for those regions with > 2 AZs) and any unexpected future network requirements 
* The /20 spare CIDR blocks provide the ability to further carve out smaller protected networks within each AZ  

Example with an additional private network

```
10.20.0.0/16 - VPC (company-test-eu-west-2)
    10.20.0.0/18 - eu-west-2a
        10.20.0.0/19 - private subnet (10.20.0.0/19-eu-west-2a-private)
        10.20.32.0/19
               10.20.32.0/20 - public subnet (10.20.32.0/20-eu-west-2a-public)
               10.20.48.0/20
                   10.20.48.0/21 - **optional protected network
                   10.20.56.0/21 - spare
```

* Note: Protected networks are purely optional and if not present just result in a /20 spare subnet alongside the /20 public, this approach allows us to split out at a later date and always have spare capacity so we don't box ourselves in to a corner


