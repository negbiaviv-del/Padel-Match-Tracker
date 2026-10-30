# מפעיל את מודול ההרשאות עבור שכבת הניהול של אשכול EKS.
module "eks_iam" {
  source = "../../modules/iam"

  name_prefix = local.name_prefix
  tags        = local.common_tags
}
