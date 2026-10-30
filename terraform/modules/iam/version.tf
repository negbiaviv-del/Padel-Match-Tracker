# מגדיר את ספק הענן שבו מודול ההרשאות משתמש.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}
