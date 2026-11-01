# יוצר את רשת ה־VPC הראשית של סביבת הפיתוח.
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  # מוודא שלכל אזור זמינות יש כתובת סאבנט פרטית מתאימה.
  lifecycle {
    precondition {
      condition     = length(var.availability_zones) == length(var.private_subnet_cidrs)
      error_message = "The number of Availability Zones must match the number of private subnet CIDRs."
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

# ממפה כל אזור זמינות אל כתובת הרשת הפרטית שלו.
locals {
  private_subnets = {
    for index, availability_zone in var.availability_zones :
    availability_zone => var.private_subnet_cidrs[index]
  }
}

# מחבר את ה־VPC אל האינטרנט עבור נתיב היציאה של ה־NAT.
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
  })
}

# יוצר סאבנט ציבורי קטן שבו ימוקם רק שער ה־NAT.
resource "aws_subnet" "egress" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.egress_subnet_cidr
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-egress"
  })
}

# יוצר סאבנט פרטי בכל אזור זמינות עבור פודי EKS ושירותים פנימיים.
resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name                                        = "${var.name_prefix}-private-${each.key}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
    "karpenter.sh/discovery"                    = var.cluster_name
  })
}

# מקצה כתובת ציבורית קבועה רק עבור שער ה־NAT.
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-eip"
  })
}

# מאפשר יציאה מבוקרת סאבנטים הפרטיים אל האינטרנט.
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.egress.id

  depends_on = [aws_internet_gateway.this]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat"
  })
}

# יוצר טבלת ניתוב עבור הסאבנט הציבורי של ה־NAT.
resource "aws_route_table" "egress" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-egress-routes"
  })
}

# מחבר את רשת היציאה הציבורית אל טבלת הניתוב הציבורית.
resource "aws_route_table_association" "egress" {
  subnet_id      = aws_subnet.egress.id
  route_table_id = aws_route_table.egress.id
}

# יוצר טבלת ניתוב פרטית שמוציאה תעבורה רק דרך ה־NAT.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-routes"
  })
}

# מחבר כל סאבנט פרטי אל טבלת הניתוב הפרטית.
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
