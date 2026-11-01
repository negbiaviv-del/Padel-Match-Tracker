# מחזיר את שמות המאגרים לפי סוג הרכיב.
output "repository_names" {
  description = "Names of ECR repositories indexed by component."
  value = {
    for component, repository in aws_ecr_repository.this :
    component => repository.name
  }
}

# מחזיר את כתובות המאגרים לצורך דחיפת תמונות ופריסתן.
output "repository_urls" {
  description = "Repository URLs indexed by component."
  value = {
    for component, repository in aws_ecr_repository.this :
    component => repository.repository_url
  }
}

# מחזיר את מזהי המאגרים לצורכי הרשאות ואבחון עתידי.
output "repository_arns" {
  description = "Repository ARNs indexed by component."
  value = {
    for component, repository in aws_ecr_repository.this :
    component => repository.arn
  }
}
