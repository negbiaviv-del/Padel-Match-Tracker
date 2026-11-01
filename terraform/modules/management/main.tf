# קורא פרטי AWS הדרושים ליצירת מכונת הניהול.
data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# קורא את תמונת Amazon Linux העדכנית שמנוהלת על ידי AWS.
data "aws_ssm_parameter" "amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# יוצר מסמך אמון שמאפשר רק למכונות EC2 להשתמש בתפקיד הניהול.
data "aws_iam_policy_document" "management_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# יוצר תפקיד ייעודי עבור מכונת הניהול הפרטית.
resource "aws_iam_role" "management" {
  name               = "${var.name_prefix}-management"
  assume_role_policy = data.aws_iam_policy_document.management_assume_role.json

  tags = merge(
    var.tags,
    {
      Name      = "${var.name_prefix}-management"
      Component = "private-management"
    },
  )
}

# מאפשר למכונת הניהול להתחבר אל Session Manager בלי SSH.
resource "aws_iam_role_policy_attachment" "management_ssm" {
  role       = aws_iam_role.management.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# יוצר הרשאה מצומצמת לקריאת פרטי אשכול EKS אחד בלבד.
data "aws_iam_policy_document" "describe_cluster" {
  statement {
    effect = "Allow"

    actions = [
      "eks:DescribeCluster",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:eks:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}",
    ]
  }
}

# מחבר את ההרשאה המצומצמת לתפקיד מכונת הניהול.
resource "aws_iam_role_policy" "describe_cluster" {
  name   = "${var.name_prefix}-management-describe-cluster"
  role   = aws_iam_role.management.id
  policy = data.aws_iam_policy_document.describe_cluster.json
}

# מחבר את תפקיד ההרשאות אל מכונת EC2.
resource "aws_iam_instance_profile" "management" {
  name = "${var.name_prefix}-management"
  role = aws_iam_role.management.name
}

# יוצר קבוצת אבטחה ללא כניסה פתוחה מהרשת.
resource "aws_security_group" "management" {
  name        = "${var.name_prefix}-management"
  description = "Private management host with no inbound access."
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name      = "${var.name_prefix}-management"
      Component = "private-management"
    },
  )
}

# מאפשר יציאה מוצפנת בלבד ל־AWS, ל־Session Manager ולממשק EKS.
resource "aws_vpc_security_group_egress_rule" "management_https" {
  security_group_id = aws_security_group.management.id

  description = "Allows outbound HTTPS for AWS service access."
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = "0.0.0.0/0"
}

# יוצר מכונת ניהול פרטית ללא כתובת ציבורית וללא מפתח SSH.
resource "aws_instance" "management" {
  ami           = data.aws_ssm_parameter.amazon_linux.value
  instance_type = var.instance_type

  subnet_id                   = var.subnet_id
  associate_public_ip_address = false

  vpc_security_group_ids = [
    aws_security_group.management.id,
  ]

  iam_instance_profile = aws_iam_instance_profile.management.name

  # מוודא שסוכן Session Manager פעיל בעת עליית המכונה.
  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail

    systemctl enable amazon-ssm-agent
    systemctl restart amazon-ssm-agent
  EOF

  # מחייב שימוש ב־IMDSv2 עבור פרטי ההרשאות של המכונה.
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # שומר דיסק מוצפן קטן שנמחק יחד עם המכונה.
  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = 8
    volume_type           = "gp3"
  }

  tags = merge(
    var.tags,
    {
      Name      = "${var.name_prefix}-management"
      Component = "private-management"
    },
  )

  # ממתין שתפקיד Session Manager יתחבר לפני הפעלת המכונה.
  depends_on = [
    aws_iam_role_policy_attachment.management_ssm,
    aws_iam_role_policy.describe_cluster,
  ]
}
