#
# Create a VPC - v2
# This simply makes a VPC, but we are hardcoding CIDRs and environment names which isn't smart
# And we could be using a re-usable helper for the tags instead of defining them here, which
# can lead to having to re-define them on almost every resource.  We're using the "official" hashicorp
# terraform module registry for this VPC module.  You could just as easily clone this module to 
# adjust it to our VPC configuration standards and link the source to a github repository.
# 
# For more about this module: https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/
# 

# This is the provider we want to use / configure
provider "aws" {
  region = "${var.region}"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "farley-vpc"
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
