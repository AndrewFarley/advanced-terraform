output "public_ips" {
  description = "The public IP(s) of this instance (if exists)"
  value       = ["${aws_instance.this.*.public_ip}"]
}

output "private_ips" {
  description = "The public IP(s) of this instance"
  value       = ["${aws_instance.this.*.private_ip}"]
}

output "instance_ids" {
  description = "The Instance ID(s) of this instance"
  value       = ["${aws_instance.this.*.instance_id}"]
}

 