# מחזיר את שם המאגר כדי שנוכל לחבר אליו סביבות Terraform אחרות.
output "state_bucket_name" {
  description = "Name of the S3 bucket that stores Terraform state."
  value       = aws_s3_bucket.terraform_state.bucket
}

# מחזיר את מזהה המאגר לצורכי אבחון והרשאות עתידיות.
output "state_bucket_arn" {
  description = "ARN of the S3 bucket that stores Terraform state."
  value       = aws_s3_bucket.terraform_state.arn
}

# מחזיר את האזור שבו נשמר מצב התשתית.
output "state_bucket_region" {
  description = "AWS region of the Terraform state bucket."
  value       = var.aws_region
}
