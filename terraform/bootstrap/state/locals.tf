# בונה שם ייחודי גלובלית עבור מאגר מצב התשתית.
locals {
  state_bucket_name = lower(
    "${var.project_name}-${data.aws_caller_identity.current.account_id}-${var.aws_region}-tfstate"
  )
}
