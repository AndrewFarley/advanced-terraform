#
# Create a VPC - v3
# This simply makes a VPC, properly using Terraform's interpolators and variables 
# to never hardcode anything into our terraform files, to maximize re-use.  Notice
# the usage of Terraform's interpolation helper (cidrsubnet) to extract a sub-subnet.
# Also notice we're using the local.tags feature (defined in variables.tf).  It's a way
# to define a variable, map, or list and re-use it in numerous places which would lead to
# having to edit it in multiple places if you want to change it
# 
# For more, see: https://www.terraform.io/docs/configuration/interpolation.html
#           and: https://www.terraform.io/docs/configuration/locals.html
# 
# This is the provider we want to use / configure
provider "aws" {
  region = "${var.region}"
}

# This is the configuration for a 3+ az AWS region
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.env}-vpc"
  cidr = "${var.cidr}"

  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets = ["${cidrsubnet(var.cidr, 8, 1)}", "${cidrsubnet(var.cidr, 8, 2)}", "${cidrsubnet(var.cidr, 8, 3)}"]
  public_subnets  = ["${cidrsubnet(var.cidr, 8, 101)}", "${cidrsubnet(var.cidr, 8, 102)}", "${cidrsubnet(var.cidr, 8, 103)}"]

  enable_nat_gateway = true

  tags = "${local.tags}"
}
