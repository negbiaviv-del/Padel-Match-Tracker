# מגדיר את ספק אמזון ואת האזור שבו ינוהלו המשאבים.
provider "aws" {
  region = var.aws_region

  # מוסיף תגיות אחידות לכל משאב שיווצר בשכבת האתחול.
  default_tags {
    tags = merge(
      var.tags,
      {
        Project   = var.project_name
        ManagedBy = "Terraform"
        Component = "terraform-state"
      },
    )
  }
}

# קורא את פרטי החשבון שאליו Terraform מחובר.
data "aws_caller_identity" "current" {}
