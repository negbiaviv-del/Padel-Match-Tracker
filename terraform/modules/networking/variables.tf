# מגדיר קידומת אחידה לשמות משאבי הרשת.
variable "name_prefix" {
  description = "Prefix used in networking resource names."
  type        = string
}

# מגדיר את שם אשכול הקלאסטר עבור תגיות גילוי הסאבנטים.
variable "cluster_name" {
  description = "EKS cluster name used in subnet discovery tags."
  type        = string
}

# מגדיר את טווח כתובות הרשת הראשי של ה-VPC.
variable "vpc_cidr" {
  description = "CIDR block assigned to the VPC."
  type        = string
}

# מגדיר לפחות שני אזורי זמינות עבור הסאבנטים הפרטיים.
variable "availability_zones" {
  description = "Availability Zones used by the private workload subnets."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two Availability Zones are required."
  }
}

# מגדיר טווח כתובות לכל סאבנט פרטי של עומסי העבודה.
variable "private_subnet_cidrs" {
  description = "CIDR blocks for private workload subnets, one per Availability Zone."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least two private subnet CIDR blocks are required."
  }
}

# מגדיר סאבנט ציבורית ייעודית ל-NAT Gateway בלבד.
variable "egress_subnet_cidr" {
  description = "CIDR block for the public subnet that hosts the NAT Gateway."
  type        = string
}

# מגדיר תגיות נוספות שנעביר לכל משאב במודול.
variable "tags" {
  description = "Additional tags applied to networking resources."
  type        = map(string)
  default     = {}
}
