# מגדיר קידומת אחידה לשמות משאבי Karpenter.
variable "name_prefix" {
  description = "Prefix used for Karpenter resource names."
  type        = string
}

# מגדיר את שם אשכול EKS שבו Karpenter ינהל מכונות.
variable "cluster_name" {
  description = "Name of the EKS cluster managed by Karpenter."
  type        = string
}

# מגדיר את כתובת ספק הזהויות של אשכול EKS.
variable "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL used to trust the Karpenter service account."
  type        = string
}

# מגדיר את קבוצת האבטחה הראשית שנוצרה אוטומטית עבור אשכול EKS.
variable "cluster_security_group_id" {
  description = "Cluster security group ID used by Karpenter-managed nodes."
  type        = string
}

# מגדיר את מרחב השמות שבו בקר Karpenter ירוץ.
variable "karpenter_namespace" {
  description = "Kubernetes namespace used by the Karpenter controller."
  type        = string
  default     = "karpenter"
}

# מגדיר את שם חשבון השירות של בקר Karpenter.
variable "karpenter_service_account_name" {
  description = "Kubernetes service account name used by Karpenter."
  type        = string
  default     = "karpenter"
}

# מגדיר תגיות משותפות לכל משאבי AWS של Karpenter.
variable "tags" {
  description = "Tags applied to Karpenter AWS resources."
  type        = map(string)
  default     = {}
}
