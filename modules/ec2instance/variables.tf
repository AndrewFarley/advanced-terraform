variable "name" {
  description = "Name to be used on all the resources as identifier"
  default     = "web"
}

variable "vpc_id" {
  description = "VPC to use"
  default     = ""
}

variable "keypair_name" {
  description = "Keypair to use"
  default     = ""
}

variable "subnet_ids" {
  description = "Subnet IDs to use"
  default     = []
}

variable "security_groups" {
  description = "A list of security groups to additionally assign to this instance"
  default     = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
}

variable "user_data" {
  description = "The userdata to use"
  default     = ""
}