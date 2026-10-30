# מגדיר קידומת אחידה לשמות תפקידי ההרשאה.
variable "name_prefix" {
  description = "Prefix used for IAM role names."
  type        = string
}

# מגדיר תגיות משותפות לכל משאב במודול.
variable "tags" {
  description = "Tags applied to IAM resources."
  type        = map(string)
  default     = {}
}
