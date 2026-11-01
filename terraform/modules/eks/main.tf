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

  # מחבר את האשכול לסאבנטים הפרטיים ומגדיר נתיב ניהול פרטי בלבד.
  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access

    # מוסיף כתובות ציבוריות רק אם נתיב ציבורי הופעל במפורש.
    public_access_cidrs = var.endpoint_public_access ? var.public_access_cidrs : null
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

# מאפשר רק למכונת הניהול הפרטית לגשת לממשק EKS בפורט מאובטח.
resource "aws_vpc_security_group_ingress_rule" "cluster_api_from_management" {
  security_group_id            = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  referenced_security_group_id = var.management_security_group_id

  description = "Allows private EKS API access from the management instance."
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  # ממתין ליצירת קבוצת האבטחה האוטומטית של האשכול.
  depends_on = [aws_eks_cluster.this]
}

# יוצר קבוצת מכונות עובדים מנוהלת שעליה ירוצו הפודים של היישום.
resource "aws_eks_node_group" "workers" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-workers"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  # בוחר תמונת מערכת הפעלה עדכנית עבור מכונות EKS.
  ami_type = "AL2023_x86_64_STANDARD"

  # משתמש במכונות On-Demand יציבות עבור סביבת הפיתוח.
  capacity_type = var.node_capacity_type

  # מגדיר את סוגי מכונות EC2 שמותר לקבוצת העובדים ליצור.
  instance_types = var.node_instance_types

  # מקצה נפח דיסק מקומי למערכת ההפעלה, לקונטיינרים וליומנים.
  disk_size = var.node_disk_size

  # מגדיר כמה מכונות ירוצו וכמה מותר להרחיב בעתיד.
  scaling_config {
    min_size     = var.node_min_size
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
  }

  # מאפשר לעדכן בכל פעם לכל היותר מכונת עובד אחת.
  update_config {
    max_unavailable = 1
  }

  # מסמן את המכונות כיעד כללי לעומסי העבודה של היישום.
  labels = {
    workload = "general"
  }

  tags = merge(
    var.tags,
    {
      Name      = "${var.cluster_name}-workers"
      Component = "eks-worker-node"
    },
  )

  # מוודא שסדר גדלי הקבוצה הגיוני לפני יצירה ב־AWS.
  lifecycle {
    precondition {
      condition = (
        var.node_min_size <= var.node_desired_size &&
        var.node_desired_size <= var.node_max_size
      )

      error_message = "Node group sizing must satisfy min_size <= desired_size <= max_size."
    }
  }

  # ממתין שהאשכול יסתיים לפני יצירת מכונות העובדים.
  depends_on = [aws_eks_cluster.this]
}

# יוצר רשומת גישה מפורשת למנהל האשכול הראשי.
resource "aws_eks_access_entry" "cluster_admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.cluster_admin_principal_arn
  type          = "STANDARD"
}

# מעניק למנהל האשכול הראשי הרשאות מלאות ברמת האשכול.
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

# יוצר רשומת גישה למכונת הניהול הפרטית בלבד.
resource "aws_eks_access_entry" "management" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.management_role_arn
  type          = "STANDARD"
}

# מעניק למכונת הניהול הרשאות ניהול עבור פעולות תשתית ופריסה.
resource "aws_eks_access_policy_association" "management" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.management_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  # מחיל את ההרשאה על כל האשכול.
  access_scope {
    type = "cluster"
  }

  # מוודא שרשומת הגישה נוצרה לפני חיבור המדיניות.
  depends_on = [aws_eks_access_entry.management]
}
