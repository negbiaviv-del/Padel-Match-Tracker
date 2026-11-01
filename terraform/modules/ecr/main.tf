# יוצר מאגר תמונות נפרד לכל רכיב של היישום.
resource "aws_ecr_repository" "this" {
  for_each = var.repository_suffixes

  name                 = "${var.name_prefix}-${each.value}"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = false

  # מצפין את התמונות הנשמרות במאגר.
  encryption_configuration {
    encryption_type = "AES256"
  }

  # מבקש מאמזון לסרוק תמונה חדשה בעת העלאתה.
  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  # מוסיף תגיות אחידות לצורכי זיהוי וניהול.
  tags = merge(
    var.tags,
    {
      Name      = "${var.name_prefix}-${each.value}"
      Component = "container-registry"
      Service   = each.value
    },
  )
}

# מוחק אוטומטית גרסאות ישנות כדי למנוע הצטברות ועלויות אחסון.
resource "aws_ecr_lifecycle_policy" "this" {
  for_each = aws_ecr_repository.this

  repository = each.value.name

  policy = jsonencode(
    {
      rules = [
        {
          rulePriority = 1
          description  = "Keep only the most recent commit-tagged images."

          selection = {
            tagStatus     = "tagged"
            tagPrefixList = ["sha-"]
            countType     = "imageCountMoreThan"
            countNumber   = var.max_tagged_images
          }

          action = {
            type = "expire"
          }
        },
        {
          rulePriority = 2
          description  = "Expire untagged images after one day."

          selection = {
            tagStatus   = "untagged"
            countType   = "sinceImagePushed"
            countUnit   = "days"
            countNumber = 1
          }

          action = {
            type = "expire"
          }
        },
      ]
    },
  )
}
