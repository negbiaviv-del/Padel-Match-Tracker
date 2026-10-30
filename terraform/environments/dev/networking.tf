# קורא את אזורי הזמינות הפעילים מהאזור שנבחר ב־AWS.
data "aws_availability_zones" "available" {
  state = "available"
}

# מפעיל את מודול הרשת עם הערכים של סביבת הפיתוח.
module "networking" {
  source = "../../modules/networking"

  name_prefix  = local.name_prefix
  cluster_name = local.cluster_name

  vpc_cidr = "10.42.0.0/16"

  availability_zones = slice(
    data.aws_availability_zones.available.names,
    0,
    2,
  )

  private_subnet_cidrs = [
    "10.42.0.0/20",
    "10.42.16.0/20",
  ]

  egress_subnet_cidr = "10.42.240.0/24"

  tags = local.common_tags
}
