# מחזיר את כתובת תפקיד בקר Karpenter לצורך חיבור לחשבון השירות ב־Kubernetes.
output "controller_role_arn" {
  description = "ARN of the IAM role assumed by the Karpenter controller."
  value       = aws_iam_role.controller.arn
}

# מחזיר את שם תפקיד בקר Karpenter לצורכי אבחון.
output "controller_role_name" {
  description = "Name of the IAM role assumed by the Karpenter controller."
  value       = aws_iam_role.controller.name
}

# מחזיר את כתובת תפקיד המכונות ש־Karpenter ייצור בעת עומס.
output "node_role_arn" {
  description = "ARN of the IAM role used by Karpenter-provisioned nodes."
  value       = aws_iam_role.node.arn
}

# מחזיר את שם פרופיל המכונה שנחבר ל־EC2NodeClass בהמשך.
output "node_instance_profile_name" {
  description = "Name of the IAM instance profile used by Karpenter-provisioned nodes."
  value       = aws_iam_instance_profile.node.name
}

# מחזיר את כתובת ספק הזהויות של EKS לצורכי אבחון.
output "oidc_provider_arn" {
  description = "ARN of the OIDC provider used by Karpenter."
  value       = aws_iam_openid_connect_provider.cluster.arn
}
