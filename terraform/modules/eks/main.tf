# יוצר קבוצת יומנים מנוהלת עבור שכבת הניהול של האשכול.
resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.log_retention_in_days

  tags = merge(
    var.tags,
    {
      Name      = "${var.cluster_name}-control-plane-logs"
      Component = "eks-control-plane"
    },
  )
}

# יוצר את אשכול EKS ומחבר אותו לרשת הפרטית ולתפקיד ההרשאות.
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.kubernetes_version

  # מפעיל רק יומני ניהול חשובים כדי לשמור על עלויות נמוכות.
  enabled_cluster_log_types = var.enabled_cluster_log_types

  # משתמש במערכת הגישה העדכנית של EKS.
  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = false
  }

  # נשאר בתמיכה רגילה כדי להימנע מתמחור תמיכה מורחבת.
  upgrade_policy {
    support_type = "STANDARD"
  }

  # מחבר את האשכול לסאבנטים הפרטיים ומגדיר את נתיבי הגישה לניהול.
  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
  }

  tags = merge(
    var.tags,
    {
      Name      = var.cluster_name
      Component = "eks-control-plane"
    },
  )

  # מוודא שקבוצת היומנים קיימת לפני שהאשכול שולח אליה מידע.
  depends_on = [aws_cloudwatch_log_group.cluster]
}

# יוצר רשומת גישה מפורשת למנהל האשכול.
resource "aws_eks_access_entry" "cluster_admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.cluster_admin_principal_arn
  type          = "STANDARD"
}

# מעניק למנהל האשכול הרשאות מלאות ברמת האשכול.
resource "aws_eks_access_policy_association" "cluster_admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.cluster_admin_principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  # מחיל את ההרשאה על כל האשכול.
  access_scope {
    type = "cluster"
  }

  # מוודא שרשומת הגישה נוצרה לפני חיבור המדיניות.
  depends_on = [aws_eks_access_entry.cluster_admin]
}
