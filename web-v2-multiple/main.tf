#
# Create a VPC and setup a webserver via a module - v2
# 
# This takes our previous example of making a VPC from a module and then creates an
# EC2 Instance with a simple ec2instance module that we created
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

# Upload our keypair
resource "aws_key_pair" "demo_keypair" {
    key_name = "${var.env}_keypair"
    public_key = "${file("~/.ssh/id_rsa.pub")}"
}

# We want to add SSH access to this server
resource "aws_security_group" "ssh" {
  name        = "${var.env}-allow-ssh"
  description = "${var.env} - Allow SSH"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# A multi module'd webserver (using trickery inside the module, not using count here, unfortunately)
module "webserver" {
  source            = "../modules/ec2instance"
  
  name              = "${var.env}-web"
  vpc_id            = "${module.vpc.vpc_id}"
  keypair_name      = "${aws_key_pair.demo_keypair.key_name}"
  subnet_ids        = "${module.vpc.public_subnets}"
  security_groups   = ["${aws_security_group.ssh.id}"]
  user_data         = "${file("../helpers/install-apache.sh")}"

  tags              = "${local.tags}"
}

# This is the "output" to print to the screen
output "webserver_public_ip" {
  description = "Public IP of our webserver"
  value       = "${module.webserver.public_ips}"
}
