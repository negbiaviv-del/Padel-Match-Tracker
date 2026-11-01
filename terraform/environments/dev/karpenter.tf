# מפעיל את מודול Karpenter עבור הרחבת מכונות דינמית.
module "karpenter" {
  source = "../../modules/karpenter"

  # מחבר את Karpenter אל אשכול EKS שנוצר בסביבה.
  cluster_name = module.eks.cluster_name

  # מחבר את ספק הזהויות של האשכול להרשאות חשבון השירות.
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url

  # מסמן את קבוצת האבטחה ש־Karpenter ישתמש בה למכונות חדשות.
  cluster_security_group_id = module.eks.cluster_security_group_id

  # שומר קידומת ותגיות אחידות למשאבי Karpenter.
  name_prefix = local.name_prefix
  tags        = local.common_tags

  # מוודא שהאשכול נוצר לפני משאבי Karpenter.
  depends_on = [
    module.eks,
  ]
}
