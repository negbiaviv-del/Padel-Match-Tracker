# יוצר מסמך אמון שמאפשר רק לשירות EKS להשתמש בתפקיד.
data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

# יוצר תפקיד ייעודי עבור שכבת הניהול של אשכול EKS.
resource "aws_iam_role" "eks_cluster" {
  name               = "${var.name_prefix}-eks-cluster"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-eks-cluster"
    Component = "eks-control-plane"
  })
}

# מצרף לתפקיד את מדיניות AWS הנדרשת לניהול אשכול EKS.
resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
