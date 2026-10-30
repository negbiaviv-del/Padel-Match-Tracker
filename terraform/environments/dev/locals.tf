# מגדיר ערכים פנימיים שחוזרים בכל משאבי סביבת הפיתוח.
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = "Padel-Match-Tracker"
  }
}
