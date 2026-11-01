# מגדיר קידומת אחידה לשמות משאבי הניהול.
variable "name_prefix" {
  description = "Prefix used for management resource names."
  type        = string
}

# מגדיר את שם אשכול EKS שמכונת הניהול תוכל לזהות.
variable "cluster_name" {
  description = "Name of the EKS cluster managed from the private instance."
  type        = string
}

# מגדיר את מזהה רשת ה־VPC שבה תוקם המכונה.
variable "vpc_id" {
  description = "ID of the VPC that contains the management instance."
  type        = string
}

# מגדיר את הסאבנט הפרטי שבו תוקם מכונת הניהול.
variable "subnet_id" {
  description = "Private subnet ID used by the management instance."
  type        = string
}

# מגדיר את סוג מכונת הניהול.
variable "instance_type" {
  description = "EC2 instance type used by the private management host."
  type        = string
}

# מעביר תגיות משותפות לכל משאבי הניהול.
variable "tags" {
  description = "Tags applied to management resources."
  type        = map(string)
  default     = {}
}
