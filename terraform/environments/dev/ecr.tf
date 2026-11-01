# מפעיל את מודול מאגרי התמונות עבור סביבת הפיתוח.
module "ecr" {
  source = "../../modules/ecr"

  # משתמש בקידומת האחידה של סביבת הפיתוח.
  name_prefix = local.name_prefix

  # יוצר מאגר נפרד עבור צד השרת ועבור הממשק.
  repository_suffixes = [
    "backend",
    "frontend",
  ]

  # מונע דריסה של תג תמונה שכבר קיים.
  image_tag_mutability = "IMMUTABLE"

  # מבקש סריקת אבטחה בעת העלאת תמונה חדשה.
  scan_on_push = true

  # שומר עד חמש עשרה גרסאות מתויגות לכל רכיב.
  max_tagged_images = 15

  # מוסיף את התגיות המשותפות של סביבת הפיתוח.
  tags = local.common_tags
}
