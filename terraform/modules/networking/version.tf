# מגדיר את גרסת המינימום של ספק AWS הנדרשת למודול הרשת.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}
