# Our backend security group to access the bastion server that allows us to connect to other
# private servers in the VPC
resource "aws_security_group" "bastion" {
  name        = "${var.name_prefix}-bastion-sg"
  description = "Used as a bastion for accessing private servrs"
  vpc_id      = "${aws_vpc.default.id}"

  # no inbound internet traffic!

  # SSH access from allowed ip addresses
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.allowed_ip_addresses}"
  }
  
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "bastion" {
  # The connection block tells our provisioner how to communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "ubuntu"

    # The connection will use the local SSH agent for authentication.
  }

  instance_type = "${var.bastion_instance_type}"
  ami = "${var.aws_ami}"
  
  tags {
    Name = "${var.name_prefix}-bastion"
  }

  # use the instance profile for ssh permissioning
  iam_instance_profile = "${aws_iam_instance_profile.bastion_profile.name}"

  # The name of our SSH keypair we created
  key_name = "${aws_key_pair.auth.id}"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.bastion.id}"]

  # We're going to launch into a public subnet so the bastion gets a public IP
  subnet_id = "${aws_subnet.public.id}"

  # build the tar files needed for deployment
  provisioner "local-exec" {
    command = "bash bin/build.sh"
  }

  # this runs the needed bootstrap scripts
  provisioner "file" {
    source = "bin/bootstrap.tar"
    destination = "/tmp/bootstrap.tar"
  }
  
  # this sets up streamsets and some dependencies
  provisioner "file" {
    source = "bin/streamsets.tar"
    destination = "/tmp/streamsets.tar"
  }

  # We run a remote provisioner on the instance after creating it.
  provisioner "remote-exec" {
    inline = [
      # set up THIS instance
      "sudo tar -xf /tmp/bootstrap.tar -C /tmp",
      "sudo bash /tmp/bootstrap/run.sh",
      
      # set up STREAMSETS instance

      # this solves the 'you SURE you want to connect?' prompt
      "ssh-keyscan -H ${aws_instance.streamsets.private_ip} >> ~/.ssh/known_hosts",

      # send over all the files we need
      "scp /tmp/bootstrap.tar ubuntu@${aws_instance.streamsets.private_ip}:/tmp/bootstrap.tar",
      "scp /tmp/streamsets.tar ubuntu@${aws_instance.streamsets.private_ip}:/tmp/streamsets.tar",
      
      # extract and run the scripts we just sent
      "ssh ubuntu@${aws_instance.streamsets.private_ip} 'sudo tar -xf /tmp/bootstrap.tar -C /tmp'",
      "ssh ubuntu@${aws_instance.streamsets.private_ip} 'sudo tar -xf /tmp/streamsets.tar -C /tmp'",
      "ssh ubuntu@${aws_instance.streamsets.private_ip} 'sudo bash /tmp/bootstrap/run.sh'",
      "ssh ubuntu@${aws_instance.streamsets.private_ip} 'sudo bash /tmp/streamsets/run.sh'",
    ]
  }
}

# Used by the IAM ssh access roles
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${var.name_prefix}-bastion-instance-profile"
  role = "${aws_iam_role.role.name}"
}

# Used by the IAM ssh access roles
resource "aws_iam_role_policy_attachment" "bastion-attachment" {
  role = "${aws_iam_role.role.name}"
  policy_arn = "${aws_iam_policy.policy.arn}"
}
