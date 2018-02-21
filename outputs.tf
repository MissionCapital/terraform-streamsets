output "elb_address" {
  value = "${aws_elb.web.dns_name}"
}

output "bastion_ip" {
  value = "${aws_instance.bastion.public_ip}"
}
