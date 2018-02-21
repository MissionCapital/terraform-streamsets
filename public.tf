# elastic load balancer to handle requests coming in
resource "aws_elb" "web" {
  name = "${var.name_prefix}-elb"

  # need the public subnet in there for access to the internet gateway,
  # and the private one for access to the instances.
  # Public needs to be first or it will launch into the private and mess things up
  subnets         = ["${aws_subnet.public.id}", "${aws_subnet.private.id}"]
  security_groups = ["${aws_security_group.elb.id}"]
  instances       = ["${aws_instance.streamsets.id}"]

  # translate HTTPS/443 requests coming in to HTTPS/18630 on the instance
  listener {
    instance_port     = "${var.streamsets_port}"
    instance_protocol = "https"
    lb_port           = 443
    lb_protocol       = "https"
    ssl_certificate_id = "${var.ssl_cert_arn}"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTPS:${var.streamsets_port}/"
    interval            = 30
  }
}

# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "elb" {
  name        = "${var.name_prefix}-elb-security-group"
  description = "Used in the terraform streamsets deploy"
  vpc_id      = "${aws_vpc.default.id}"

  # HTTPS access from allowed ip addresses
  ingress {
    from_port   = 443
    to_port     = 443
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
