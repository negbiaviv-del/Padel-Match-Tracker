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

# מגדיר את סוג מכונות העובדים של סביבת הפיתוח.
variable "eks_node_instance_types" {
  description = "EC2 instance types used by development worker nodes."
  type        = list(string)
  default     = ["t3.small"]
}

# מגדיר שימוש במכונות יציבות במקום Spot לסביבת הפיתוח.
variable "eks_node_capacity_type" {
  description = "Capacity type used by development worker nodes."
  type        = string
  default     = "ON_DEMAND"
}

# משאיר לפחות שתי מכונות עובדים זמינות לפי דרישת המטלה.
variable "eks_node_min_size" {
  description = "Minimum number of development worker nodes."
  type        = number
  default     = 2
}

# יוצר שתי מכונות עובדים כבר בהקמה הראשונית.
variable "eks_node_desired_size" {
  description = "Desired number of development worker nodes."
  type        = number
  default     = 2
}

# משאיר את קבוצת הבסיס על שתי מכונות קבועות.
variable "eks_node_max_size" {
  description = "Maximum number of development worker nodes."
  type        = number
  default     = 2
}

# מגדיר דיסק מקומי מינימלי למכונת עובד.
variable "eks_node_disk_size" {
  description = "Root disk size in GiB for each development worker node."
  type        = number
  default     = 20
}

# מגדיר את סוג מכונת הניהול הפרטית.
variable "management_instance_type" {
  description = "EC2 instance type used by the private management host."
  type        = string
  default     = "t3.micro"
}

# שומר תאימות לקובץ הגדרות ישן, אך אינו מופעל בסביבה הפרטית.
variable "eks_public_access_cidrs" {
  description = "CIDR ranges reserved only if a public EKS endpoint is enabled in another environment."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.eks_public_access_cidrs : can(cidrhost(cidr, 0))
    ])

    error_message = "Each public access value must be a valid CIDR range."
  }
}

# מגדיר את זהות ה־IAM שתהיה מנהלת האשכול.
variable "cluster_admin_principal_arn" {
  description = "IAM principal ARN granted administrator access to the EKS cluster."
  type        = string
}
