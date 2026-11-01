# מחזיר את מזהה מכונת הניהול לצורך התחברות דרך Session Manager.
output "instance_id" {
  description = "ID of the private management EC2 instance."
  value       = aws_instance.management.id
}

# מחזיר את הכתובת הפרטית של מכונת הניהול לצורכי אבחון.
output "private_ip" {
  description = "Private IP address of the management EC2 instance."
  value       = aws_instance.management.private_ip
}

# מחזיר את מזהה קבוצת האבטחה של מכונת הניהול.
output "security_group_id" {
  description = "Security group ID attached to the management EC2 instance."
  value       = aws_security_group.management.id
}

# מחזיר את תפקיד ההרשאות של מכונת הניהול.
output "role_arn" {
  description = "IAM role ARN used by the management EC2 instance."
  value       = aws_iam_role.management.arn
}
