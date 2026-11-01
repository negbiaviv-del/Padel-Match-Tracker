# מגדיר את אזור אמזון שבו ייווצר מאגר מצב התשתית.
variable "aws_region" {
  description = "AWS region for the Terraform state bucket."
  type        = string
  default     = "us-east-1"
}

# מגדיר את שם הפרויקט שישמש בשם המאגר ובתגיות.
variable "project_name" {
  description = "Project name used for the Terraform state bucket."
  type        = string
  default     = "padel-match-tracker"

  validation {
    condition     = length(trimspace(var.project_name)) > 0
    error_message = "project_name must not be empty."
  }
}

# מגדיר כמה ימים לשמור גרסאות ישנות של מצב התשתית.
variable "noncurrent_version_expiration_days" {
  description = "Days to retain noncurrent Terraform state versions."
  type        = number
  default     = 90

  validation {
    condition     = var.noncurrent_version_expiration_days > 0
    error_message = "noncurrent_version_expiration_days must be greater than zero."
  }
}

# מגדיר תגיות משותפות למשאבי שכבת האתחול.
variable "tags" {
  description = "Tags applied to Terraform state resources."
  type        = map(string)
  default     = {}
}
