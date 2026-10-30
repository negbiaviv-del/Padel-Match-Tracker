# מציג את שם אשכול ה־EKS המתוכנן.
output "cluster_name" {
  description = "Planned name of the EKS cluster."
  value       = local.cluster_name
}

# מציג את מזהה רשת ה־VPC שנוצרה עבור הסביבה.
output "vpc_id" {
  description = "ID of the development VPC."
  value       = module.networking.vpc_id
}

# מציג את מזהי הרשתות הפרטיות שבהן ירוצו עומסי העבודה.
output "private_subnet_ids" {
  description = "IDs of private workload subnets."
  value       = module.networking.private_subnet_ids
}

# מציג את מזהה שער ה־NAT היחיד של סביבת הפיתוח.
output "nat_gateway_id" {
  description = "ID of the development NAT Gateway."
  value       = module.networking.nat_gateway_id
}
