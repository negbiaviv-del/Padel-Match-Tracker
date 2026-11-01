# מחזיר את שם אשכול EKS המתוכנן.
output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
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

# מחזיר את כתובת תפקיד ה־IAM של שכבת הניהול.
output "eks_cluster_role_arn" {
  description = "ARN of the IAM role used by the EKS control plane."
  value       = module.eks_iam.eks_cluster_role_arn
}

# מחזיר את כתובת ה־ARN של האשכול.
output "eks_cluster_arn" {
  description = "ARN of the EKS cluster."
  value       = module.eks.cluster_arn
}

# מחזיר את כתובת ה־API הפרטית של האשכול.
output "eks_cluster_endpoint" {
  description = "Private API endpoint of the EKS cluster."
  value       = module.eks.cluster_endpoint
}

# מחזיר את כתובת ספק הזהויות של האשכול.
output "eks_cluster_oidc_issuer_url" {
  description = "OIDC issuer URL of the EKS cluster."
  value       = module.eks.cluster_oidc_issuer_url
}

# מחזיר את שם קבוצת יומני הניהול.
output "eks_control_plane_log_group_name" {
  description = "CloudWatch log group used by the EKS control plane."
  value       = module.eks.control_plane_log_group_name
}

# מחזיר את מזהה מכונת הניהול לצורך התחברות דרך Session Manager.
output "management_instance_id" {
  description = "ID of the private management EC2 instance."
  value       = module.management.instance_id
}

# מחזיר את כתובת מכונת הניהול בתוך הרשת הפרטית.
output "management_private_ip" {
  description = "Private IP address of the management EC2 instance."
  value       = module.management.private_ip
}

# מחזיר את תפקיד ההרשאות של מכונת הניהול.
output "management_role_arn" {
  description = "IAM role ARN used by the management EC2 instance."
  value       = module.management.role_arn
}

# מחזיר את שמות מאגרי התמונות של סביבת הפיתוח.
output "ecr_repository_names" {
  description = "Names of ECR repositories for the development environment."
  value       = module.ecr.repository_names
}

# מחזיר את כתובות מאגרי התמונות לצורך בנייה ופריסה.
output "ecr_repository_urls" {
  description = "URLs of ECR repositories for the development environment."
  value       = module.ecr.repository_urls
}

# מחזיר את מזהי מאגרי התמונות לצורכי הרשאות ואבחון.
output "ecr_repository_arns" {
  description = "ARNs of ECR repositories for the development environment."
  value       = module.ecr.repository_arns
}

# מחזיר את תפקיד בקר Karpenter לצורך חיבור לחשבון השירות.
output "karpenter_controller_role_arn" {
  description = "ARN of the IAM role used by the Karpenter controller."
  value       = module.karpenter.controller_role_arn
}

# מחזיר את תפקיד מכונות Karpenter לצורכי אבחון והרשאות.
output "karpenter_node_role_arn" {
  description = "ARN of the IAM role used by Karpenter-provisioned nodes."
  value       = module.karpenter.node_role_arn
}

# מחזיר את פרופיל המכונה שנחבר ל־EC2NodeClass בהמשך.
output "karpenter_node_instance_profile_name" {
  description = "Name of the IAM instance profile used by Karpenter-provisioned nodes."
  value       = module.karpenter.node_instance_profile_name
}
