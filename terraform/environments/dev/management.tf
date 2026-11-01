# מפעיל מכונת ניהול פרטית עבור גישה לאשכול ולניטור.
module "management" {
  source = "../../modules/management"

  # משתמש באותו שם אחיד של סביבת הפיתוח.
  name_prefix = local.name_prefix

  # מגביל את הרשאות הקריאה לאשכול של סביבת הפיתוח בלבד.
  cluster_name = local.cluster_name

  # מחבר את מכונת הניהול לרשת הפרטית שכבר נוצרה.
  vpc_id    = module.networking.vpc_id
  subnet_id = module.networking.private_subnet_ids[0]

  # בוחר מכונה קטנה שמתאימה לפעולות ניהול.
  instance_type = var.management_instance_type

  # מעביר תגיות אחידות לצורכי זיהוי ועלויות.
  tags = local.common_tags
}
