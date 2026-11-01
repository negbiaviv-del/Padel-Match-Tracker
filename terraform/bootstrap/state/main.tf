# יוצר מאגר פרטי עבור מצב התשתית של Terraform.
resource "aws_s3_bucket" "terraform_state" {
  bucket        = local.state_bucket_name
  force_destroy = false

  # מונע מחיקה מקרית של מאגר מצב התשתית.
  lifecycle {
    prevent_destroy = true
  }
}

# מפעיל שמירת גרסאות כדי לאפשר שחזור של מצב קודם.
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  # שומר כל גרסה חדשה של קובץ המצב.
  versioning_configuration {
    status = "Enabled"
  }
}

# מצפין את קובץ מצב התשתית בזמן שמירתו במאגר.
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  # משתמש בהצפנת ברירת המחדל של שירות האחסון.
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# חוסם כל אפשרות לגישה ציבורית אל מאגר מצב התשתית.
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  # חוסם רשימות גישה ציבוריות.
  block_public_acls = true

  # חוסם מדיניות גישה ציבורית.
  block_public_policy = true

  # מתעלם מרשימות גישה ציבוריות קיימות.
  ignore_public_acls = true

  # מגביל גישה לבעל החשבון ולשירותי אמזון בלבד.
  restrict_public_buckets = true
}

# מוחק גרסאות ישנות לאחר תקופת השמירה שהוגדרה.
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  # מוודא ששמירת הגרסאות פעילה לפני הפעלת מדיניות הניקוי.
  depends_on = [aws_s3_bucket_versioning.terraform_state]

  # מחיל את המדיניות על כל קובצי המאגר.
  rule {
    id     = "expire-noncurrent-state-versions"
    status = "Enabled"

    # בוחר את כל הקבצים במאגר.
    filter {}

    # מוחק רק גרסאות ישנות ולא את מצב התשתית הפעיל.
    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
  }
}
