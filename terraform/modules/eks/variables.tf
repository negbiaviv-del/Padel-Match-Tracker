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

# מגדיר את כתובת תפקיד ההרשאות של מכונות העובדים.
variable "node_role_arn" {
  description = "ARN of the IAM role assumed by EKS worker nodes."
  type        = string
}

# מגדיר את זהות ה־IAM שתנהל את האשכול.
variable "cluster_admin_principal_arn" {
  description = "IAM principal ARN granted cluster administrator access."
  type        = string
}

# מגדיר את הסאבנטים הפרטיים שבהם האשכול ומכונות העובדים יעבדו.
variable "subnet_ids" {
  description = "Private subnet IDs used by the EKS cluster and worker nodes."
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

# מגדיר את סוגי מכונות EC2 שמותר לקבוצת העובדים להשתמש בהם.
variable "node_instance_types" {
  description = "EC2 instance types allowed for the managed node group."
  type        = list(string)

  validation {
    condition     = length(var.node_instance_types) > 0
    error_message = "At least one worker node instance type is required."
  }
}

# מגדיר אם העובדים יופעלו כמכונות On-Demand או Spot.
variable "node_capacity_type" {
  description = "Capacity type used by the managed node group."
  type        = string

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "Node capacity type must be ON_DEMAND or SPOT."
  }
}

# מונע יצירה של פחות משתי מכונות עובדים.
variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number

  validation {
    condition     = var.node_min_size >= 2
    error_message = "At least two worker nodes are required."
  }
}

# מונע הקמה ראשונית של פחות משתי מכונות עובדים.
variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number

  validation {
    condition     = var.node_desired_size >= 2
    error_message = "Desired worker node count must be at least two."
  }
}

# מוודא שגם הגבול העליון מאפשר לפחות שתי מכונות עובדים.
variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number

  validation {
    condition     = var.node_max_size >= 2
    error_message = "Maximum worker node count must be at least two."
  }
}

# מגדיר את גודל הדיסק המקומי של כל מכונת עובד.
variable "node_disk_size" {
  description = "Root disk size in GiB for each worker node."
  type        = number

  validation {
    condition     = var.node_disk_size >= 20
    error_message = "Worker node disk size must be at least 20 GiB."
  }
}

# מעביר תגיות משותפות לכל משאבי האשכול.
variable "tags" {
  description = "Tags applied to EKS resources."
  type        = map(string)
}
