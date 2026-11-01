# מגדיר קידומת אחידה לשמות מאגרי התמונות.
variable "name_prefix" {
  description = "Prefix used for ECR repository names."
  type        = string

  validation {
    condition     = length(trimspace(var.name_prefix)) > 0
    error_message = "name_prefix must not be empty."
  }
}

# מגדיר את סוגי התמונות שיקבלו מאגר נפרד.
variable "repository_suffixes" {
  description = "Suffixes added to name_prefix for repository names."
  type        = set(string)
  default     = ["backend", "frontend"]

  validation {
    condition = alltrue([
      for suffix in var.repository_suffixes : length(trimspace(suffix)) > 0
    ])
    error_message = "Each repository suffix must not be empty."
  }
}

# מגדיר אם תג תמונה יכול להשתנות לאחר שנדחף למאגר.
variable "image_tag_mutability" {
  description = "Whether image tags can be overwritten."
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition = contains(
      ["MUTABLE", "IMMUTABLE"],
      var.image_tag_mutability,
    )
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

# מגדיר אם אמזון תסרוק תמונה חדשה בעת העלאתה למאגר.
variable "scan_on_push" {
  description = "Whether ECR scans newly pushed images."
  type        = bool
  default     = true
}

# מגדיר כמה גרסאות מתויגות אחרונות לשמור בכל מאגר.
variable "max_tagged_images" {
  description = "Maximum number of tagged images retained per repository."
  type        = number
  default     = 15

  validation {
    condition     = var.max_tagged_images > 0
    error_message = "max_tagged_images must be greater than zero."
  }
}

# מגדיר תגיות משותפות לכל מאגר.
variable "tags" {
  description = "Tags applied to ECR repositories."
  type        = map(string)
  default     = {}
}
