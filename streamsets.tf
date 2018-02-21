# Our backend security group to access
# the instances over SSH and HTTPS
resource "aws_security_group" "streamsets" {
  name        = "${var.name_prefix}-streamsets-sg"
  description = "Used in the terraform streamsets deploy"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access from bastion
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.public_subnet_cidr}"]
  }
  
  # Streamsets access from the ELB
  ingress {
    from_port   = "${var.streamsets_port}"
    to_port     = "${var.streamsets_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.public_subnet_cidr}"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "streamsets" {
  instance_type = "${var.streamsets_instance_type}"

  tags {
    Name = "${var.name_prefix}-streamsets"
  }

  # use the instance profile for ssh permissioning
  iam_instance_profile = "${aws_iam_instance_profile.streamsets_profile.name}"

  # Lookup the correct AMI
  ami = "${var.aws_ami}"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.streamsets.id}"]

  # The name of our SSH keypair we created
  key_name = "${aws_key_pair.auth.id}"

  # We're going to launch into the a private subnet for security
  subnet_id = "${aws_subnet.private.id}"
}

# used in the IAM ssh role access
resource "aws_iam_instance_profile" "streamsets_profile" {
  name = "${var.name_prefix}-streamsets-profile"
  role = "${aws_iam_role.role.name}"
}

# used in the IAM ssh role access
resource "aws_iam_role_policy_attachment" "streamsets-attachment" {
  role = "${aws_iam_role.role.name}"
  policy_arn = "${aws_iam_policy.policy.arn}"
}
