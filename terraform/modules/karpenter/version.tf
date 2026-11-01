# מגדיר את גרסת Terraform ואת ספקי הענן הנדרשים למודול Karpenter.
terraform {
  required_version = ">= 1.9.0"

  # מגדיר את ספק AWS ליצירת משאבי ההרשאות.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    # קורא את תעודת OIDC לצורך יצירת חיבור מאובטח להרשאות Kubernetes.
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}
