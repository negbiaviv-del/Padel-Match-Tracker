# מגדיר את שם אשכול קוברנטיס.
variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

# מגדיר את כתובת תפקיד ההרשאות של שכבת הניהול.
variable "cluster_role_arn" {
  description = "ARN of the IAM role assumed by the EKS control plane."
  type        = string
}

# מגדיר את זהות ה־IAM שתנהל את האשכול.
variable "cluster_admin_principal_arn" {
  description = "IAM principal ARN granted cluster administrator access."
  type        = string
}

# מגדיר את הסאבנטים הפרטיים שבהם האשכול יעבוד.
variable "subnet_ids" {
  description = "Private subnet IDs used by the EKS cluster."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least two private subnets are required."
  }
}

# מגדיר את גרסת קוברנטיס של האשכול.
variable "kubernetes_version" {
  description = "Kubernetes version used by the EKS cluster."
  type        = string
}

# קובע אם האשכול יאפשר נתיב פנימי לעובדים ברשת.
variable "endpoint_private_access" {
  description = "Whether the EKS API has a private VPC endpoint."
  type        = bool
}

# קובע אם האשכול יאפשר ניהול ישיר דרך האינטרנט.
variable "endpoint_public_access" {
  description = "Whether the EKS API has a public endpoint."
  type        = bool
}

# מגביל את הגישה הציבורית לכתובות מורשות בלבד.
variable "public_access_cidrs" {
  description = "CIDR ranges allowed to reach the public EKS API endpoint."
  type        = list(string)

  validation {
    condition     = length(var.public_access_cidrs) > 0
    error_message = "At least one allowed public CIDR is required."
  }
}

# מגדיר אילו יומני ניהול יישלחו ל־CloudWatch.
variable "enabled_cluster_log_types" {
  description = "EKS control-plane log types enabled for CloudWatch."
  type        = set(string)
  default     = ["api", "audit", "authenticator"]
}

# מגדיר לכמה ימים נשמור את יומני שכבת הניהול.
variable "log_retention_in_days" {
  description = "Number of days to retain EKS control-plane logs."
  type        = number
}

# מעביר תגיות משותפות לכל משאבי האשכול.
variable "tags" {
  description = "Tags applied to EKS resources."
  type        = map(string)
}
