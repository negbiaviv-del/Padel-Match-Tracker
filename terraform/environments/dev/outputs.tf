# מחזיר את שם אשכול EKS המתוכנן.
output "cluster_name" {
  description = "Name planned for the EKS cluster."
  value       = local.cluster_name
}

# מחזיר את מזהה הרשת הראשית.
output "vpc_id" {
  description = "ID of the VPC created for the environment."
  value       = module.networking.vpc_id
}

# מחזיר את מזהי הסאבנטים הפרטיים של עומסי העבודה.
output "private_subnet_ids" {
  description = "Private subnet IDs for Kubernetes workloads."
  value       = module.networking.private_subnet_ids
}

# מחזיר את מזהה שער ה־NAT לצורכי אבחון ועלויות.
output "nat_gateway_id" {
  description = "ID of the NAT Gateway used for private-subnet egress."
  value       = module.networking.nat_gateway_id
}

# מחזיר את כתובת תפקיד ה־IAM שנחבר לאשכול EKS בהמשך.
output "eks_cluster_role_arn" {
  description = "ARN of the IAM role used by the EKS control plane."
  value       = module.eks_iam.eks_cluster_role_arn
}
