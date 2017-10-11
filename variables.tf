# These are inputs we need to define, these two are fairly common (on basically every stack ever)
variable "region" { }  # The aws region we want to be working with
variable "env" { }     # This is a "prefix" which we will add to the name of everything tag to everything
variable "cidr" { }     # This is a "prefix" which we will add to the name of everything tag to everything
variable "project" {   # The name of this project, often used in naming of resources created also
  default = "terraform-advanced-usage"
}
# These are things we'll use in various places
locals {
  tags = {
    Terraform = "true"
    Environment = "${var.env}"
    Project = "${var.project}"
  }
}