# This allows us to query AWS to get the "latest" of a certain AMI from the current region to use automatically
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# Our AWS Security group in our VPC (above)
resource "aws_security_group" "this" {
  name        = "${var.name}-allow-http"
  description = "${var.name} - Allow HTTP"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

# This will spin up one server per subnet id that is passed in
resource "aws_instance" "this" {
  count                       = "${length(var.subnet_ids)}"
  
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = "${var.keypair_name}"
  subnet_id                   = "${var.subnet_ids[count.index]}"
  vpc_security_group_ids      = [ 
                                  "${aws_security_group.this.id}",
                                  "${var.security_groups}",
                                ]
  tags                        = "${merge(var.tags, map("Name", format("%s-%02d", var.name, count.index + 1)))}"
  user_data                   = "${var.user_data}"
}
 