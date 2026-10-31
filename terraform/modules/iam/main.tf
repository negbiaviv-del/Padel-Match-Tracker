# יוצר מסמך אמון שמאפשר רק לשירות EKS להשתמש בתפקיד שכבת הניהול.
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

# יוצר מסמך אמון שמאפשר למכונות EC2 של העובדים להשתמש בתפקיד.
data "aws_iam_policy_document" "eks_node_assume_role" {
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

# יוצר תפקיד ייעודי עבור מכונות העובדים של האשכול.
resource "aws_iam_role" "eks_node" {
  name               = "${var.name_prefix}-eks-node"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role.json

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-eks-node"
    Component = "eks-worker-node"
  })
}

# מאפשר לעובד להצטרף לאשכול ולבצע פעולות בסיסיות של node.
resource "aws_iam_role_policy_attachment" "eks_node_worker" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# מאפשר לעובד למשוך תמונות מכולה פרטיות מ־ECR.
resource "aws_iam_role_policy_attachment" "eks_node_ecr_pull" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

# מאפשר למכונות העובדים לנהל רשת וכתובות IP עבור פודי Kubernetes.
resource "aws_iam_role_policy_attachment" "eks_node_cni" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
