# מחזיר את כתובת ה־ARN של תפקיד שכבת הניהול.
output "eks_cluster_role_arn" {
  description = "ARN of the IAM role assumed by the EKS control plane."
  value       = aws_iam_role.eks_cluster.arn
}

# מחזיר את שם התפקיד לצורכי תצוגה ואבחון.
output "eks_cluster_role_name" {
  description = "Name of the IAM role assumed by the EKS control plane."
  value       = aws_iam_role.eks_cluster.name
}

# מחזיר את כתובת ה־ARN של תפקיד מכונות העובדים.
output "eks_node_role_arn" {
  description = "ARN of the IAM role assumed by EKS worker nodes."
  value       = aws_iam_role.eks_node.arn
}

# מחזיר את שם תפקיד מכונות העובדים.
output "eks_node_role_name" {
  description = "Name of the IAM role assumed by EKS worker nodes."
  value       = aws_iam_role.eks_node.name
}
