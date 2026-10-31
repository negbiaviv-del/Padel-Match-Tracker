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

# מגדיר את גרסת קוברנטיס של אשכול הפיתוח.
variable "kubernetes_version" {
  description = "Kubernetes version used by the development EKS cluster."
  type        = string
  default     = "1.37"
}

# מגדיר את משך שמירת יומני שכבת הניהול.
variable "eks_log_retention_in_days" {
  description = "Days to retain EKS control-plane logs in CloudWatch."
  type        = number
  default     = 14
}

# מגדיר אילו כתובות ציבוריות רשאיות לנהל את האשכול.
variable "eks_public_access_cidrs" {
  description = "CIDR ranges allowed to reach the public EKS API endpoint."
  type        = list(string)

  validation {
    condition     = length(var.eks_public_access_cidrs) > 0
    error_message = "At least one allowed public CIDR is required."
  }
}

# מגדיר את זהות ה־IAM שתהיה מנהלת האשכול.
variable "cluster_admin_principal_arn" {
  description = "IAM principal ARN granted administrator access to the EKS cluster."
  type        = string
}
