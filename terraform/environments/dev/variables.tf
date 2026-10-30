# מגדיר את אזור אמזון שבו תיווצר סביבת הפיתוח.
variable "aws_region" {
  description = "AWS region for the development environment."
  type        = string
  default     = "us-east-1"
}

# מגדיר את השם המשותף של הפרויקט והמשאבים שלו.
variable "project_name" {
  description = "Project name used in resource names and tags."
  type        = string
  default     = "padel-match-tracker"
}

# מגדיר את שם הסביבה שאליה המשאבים שייכים.
variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}
