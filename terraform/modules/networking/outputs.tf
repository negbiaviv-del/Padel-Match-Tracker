# מחזיר את מזהה רשת ה־VPC לשימוש של מודולים אחרים.
output "vpc_id" {
  description = "ID of the VPC created for the environment."
  value       = aws_vpc.this.id
}

# מחזיר את מזהי ה־subnetים הפרטיים עבור EKS ועומסי העבודה.
output "private_subnet_ids" {
  description = "IDs of private workload subnets."
  value       = [for subnet in aws_subnet.private : subnet.id]
}

# מחזיר את מזהה ה־subnet הציבורי שבו נמצא שער ה־NAT.
output "egress_subnet_id" {
  description = "ID of the public egress subnet that hosts the NAT Gateway."
  value       = aws_subnet.egress.id
}

# מחזיר את מזהה שער ה־NAT לצורכי תיעוד וחיבור עתידי.
output "nat_gateway_id" {
  description = "ID of the single development NAT Gateway."
  value       = aws_nat_gateway.this.id
}

# מחזיר את מזהה טבלת הניתוב הפרטית לצורכי הרחבה עתידית.
output "private_route_table_id" {
  description = "ID of the private route table used by workload subnets."
  value       = aws_route_table.private.id
}
