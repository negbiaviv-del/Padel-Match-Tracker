# מפעיל את מודול אשכול EKS עבור סביבת הפיתוח.
module "eks" {
  source = "../../modules/eks"

  # מחבר את שם האשכול לשם הסביבה.
  cluster_name = local.cluster_name

  # מחבר את תפקיד הניהול שנוצר במודול ההרשאות.
  cluster_role_arn = module.eks_iam.eks_cluster_role_arn

  # מגדיר את זהות מנהל האשכול.
  cluster_admin_principal_arn = var.cluster_admin_principal_arn

  # מחבר את האשכול לשני הסאבנטים הפרטיים.
  subnet_ids = module.networking.private_subnet_ids

  # מגדיר את גרסת Kubernetes של סביבת הפיתוח.
  kubernetes_version = var.kubernetes_version

  # מאפשר ניהול ישיר מהמחשב דרך כתובת ציבורית מורשית.
  endpoint_public_access = true

  # משאיר נתיב פנימי לעובדים עתידיים בתוך הרשת.
  endpoint_private_access = true

  # מגביל את הגישה הציבורית לכתובות שהוגדרו מקומית.
  public_access_cidrs = var.eks_public_access_cidrs

  # שומר את יומני הניהול לתקופה מוגבלת וחסכונית.
  log_retention_in_days = var.eks_log_retention_in_days

  # מעביר תגיות משותפות לכל משאבי האשכול.
  tags = local.common_tags

  # ממתין לסיום יצירת ההרשאות והרשת לפני יצירת האשכול.
  depends_on = [
    module.eks_iam,
    module.networking,
  ]
}
