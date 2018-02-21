data "aws_caller_identity" "current" {}

resource "aws_iam_role" "role" {
  name = "${var.name_prefix}-iam_ssh_role"
  path = "/"

  assume_role_policy = "${data.aws_iam_policy_document.iam_role_doc.json}"
}

data "aws_iam_policy_document" "iam_role_doc" {
  statement {
    sid = ""
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "get_iam_users" {
  statement {
    actions = [
      "iam:ListUsers",
      "iam:GetGroup"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "iam:GetSSHPublicKey",
      "iam:ListSSHPublicKeys"
    ]

    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/*"]
  }

  statement {
    actions = [
      "ec2:DescribeTags"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "policy" {
  name = "${var.name_prefix}-iam_ssh_policy"
  description = "Policy used to allow ssh to servers from IAM"
  policy = "${data.aws_iam_policy_document.get_iam_users.json}"
}
