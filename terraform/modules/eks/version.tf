# מגדיר את גרסאות טרהפורם וספק AWS של מודול האשכול.
terraform {
  required_version = ">= 1.14.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
