variable "public_key_path" {
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.

Example: ~/.ssh/terraform.pub
DESCRIPTION
}

variable "key_name" {
  description = "Desired name of AWS key pair"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}

variable "aws_ami" {
  description = "The specific AMI to use. AMIs are region specific so be sure  to pick the right one! Default is UBuntu 16.04"
  default = "ami-66506c1c"
}

variable "name_prefix" {
  description = "This gets appended to resource names to easily tell deployments apart"
  default = "terraform-streamsets"
}

variable "vpc_cidr" {
  description = "The base CIDR address of the VPC"
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "The CIDR address used by the public subnet"
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "The CIDR address used by the private subnet"
  default = "10.0.2.0/24"
}

variable "allowed_ip_addresses" {
  description = "The load balancer will only accept HTTPS traffic from these IP addresses. Set this to your office CIDR addresses if you want to limit traffic."
  default = ["0.0.0.0/0"]
}

variable "ssl_cert_arn" {
  description = "Create an SSL cert manually in AWS console (it is free) and use the arn here. Should look like 'arn:aws:acm:us-east-1:123456789:vertificate/UUID-OF-YOUR-CERT'"
  default = ""
}

variable "streamsets_port" {
  description = "The port we are running streamsets on. If you change this, you need to change config files in the bin directory as well"
  default = 18630
}

variable "streamsets_instance_type" {
  description = "The instance type to launch streamsets as. Note - some instance types only work on some regions"
  default = "m5.large"
}

variable "bastion_instance_type" {
  description = "Our bastion just provides ssh access to private servers. Can be tiny."
  default = "t2.micro"
}
