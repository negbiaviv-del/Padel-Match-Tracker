# מחזיר את שם האשכול שנוצר.
output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.this.name
}

# מחזיר את כתובת ה־ARN של האשכול.
output "cluster_arn" {
  description = "ARN of the EKS cluster."
  value       = aws_eks_cluster.this.arn
}

# מחזיר את כתובת ה־API של האשכול.
output "cluster_endpoint" {
  description = "API endpoint of the EKS cluster."
  value       = aws_eks_cluster.this.endpoint
}

# מחזיר את כתובת ספק הזהויות לצורך הרשאות עתידיות.
output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL of the EKS cluster."
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# מחזיר את שם קבוצת היומנים של שכבת הניהול.
output "control_plane_log_group_name" {
  description = "CloudWatch log group used by the EKS control plane."
  value       = aws_cloudwatch_log_group.cluster.name
}

# מחזיר את השם של קבוצת מכונות העובדים.
output "node_group_name" {
  description = "Name of the managed EKS worker node group."
  value       = aws_eks_node_group.workers.node_group_name
}

# מחזיר את כתובת ה־ARN של קבוצת מכונות העובדים.
output "node_group_arn" {
  description = "ARN of the managed EKS worker node group."
  value       = aws_eks_node_group.workers.arn
}

# מחזיר את מצב קבוצת מכונות העובדים לאחר יצירה.
output "node_group_status" {
  description = "Current status of the managed EKS worker node group."
  value       = aws_eks_node_group.workers.status
}
