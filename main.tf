
# This is the provider we want to use / configure
provider "aws" {
  // access_key = "123123123123"  # Intentional, use IAM Instance Role or CLI AWS Profile instead
  // secret_key = "abcabcabcabc"  # Intentional, use IAM Instance Role or CLI AWS Profile instead
  region = "${var.region}"
}

# This is a data provider, allowing us to use data from AWS within' our terraform below
data "aws_caller_identity" "current" {}

# These are inputs we need to define, these two are fairly common (on basically every stack ever)
variable "region" { }  # The aws region we want to be working with
variable "env" { }     # This is a "prefix" which we will add to the name of everything tag to everything
variable "project" {   # The name of this project, often used in naming of resources created also
  default = "terraform-module-usage"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.env}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true

  tags = {
    Terraform = "true"
    Environment = "${var.env}"
    Project = "${var.project}"
  }
}



// 
// # This is the resource we want to create (or manage/modify) in this case, a S3 bucket
// # Please see: https://www.terraform.io/docs/providers/aws/r/s3_bucket.html
// # For all the various options we can put in here 
// resource "aws_s3_bucket" "sample-bucket" {
//   bucket = "${var.env}-${var.project}-${var.region}-${data.aws_caller_identity.current.account_id}"
//   acl    = "public-read"
// 
//   tags {
//     Environment = "${var.env}"
//     Project     = "${var.project}"
//   }
// 
//   website {
//     index_document = "index.html"
//     error_document = "index.html"
//   }
// }
// 
// resource "aws_s3_bucket_object" "object" {
//   bucket = "${aws_s3_bucket.sample-bucket.id}"
//   key    = "index.html"
//   source = "./index.html"
//   etag   = "${md5(file("./index.html"))}"
//   acl    = "public-read"
//   content_type = "text/html"
// }
// 
// # This is outputs, printed on the screen, that you might want to use in other stacks (if this was a module)
// output "our_website_url_we_just_uploaded_with_terraform" {
//   value = "http://${aws_s3_bucket.sample-bucket.website_endpoint}"
// }
//  
