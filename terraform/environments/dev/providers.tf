# מגדיר את ספק אמזון עבור כל המשאבים שניצור בסביבת הפיתוח.
provider "aws" {
  region = var.aws_region

  # מוסיף תגיות אחידות לכל משאב שנוצר באמצעות טרהפורם.
  default_tags {
    tags = local.common_tags
  }
}
