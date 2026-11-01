# קורא את מחיצת AWS ואת האזור הפעיל לצורך יצירת כתובות הרשאות מדויקות.
data "aws_partition" "current" {}

data "aws_region" "current" {}

# מחלץ את כתובת ספק הזהויות ללא תחילת HTTPS.
locals {
  oidc_issuer_hostpath = trimprefix(var.cluster_oidc_issuer_url, "https://")
}

# קורא את תעודת האבטחה של ספק הזהויות של אשכול EKS.
data "tls_certificate" "cluster" {
  url = var.cluster_oidc_issuer_url
}

# יוצר ספק זהויות שמאפשר לחשבונות שירות ב־Kubernetes לקבל הרשאות AWS.
resource "aws_iam_openid_connect_provider" "cluster" {
  url = var.cluster_oidc_issuer_url

  # מגביל את קהל היעד של האסימונים לשירות AWS STS.
  client_id_list = [
    "sts.amazonaws.com",
  ]

  # שומר את טביעת האצבע של תעודת ספק הזהויות.
  thumbprint_list = [
    data.tls_certificate.cluster.certificates[0].sha1_fingerprint,
  ]

  tags = merge(
    var.tags,
    {
      Name      = "${var.name_prefix}-karpenter-oidc"
      Component = "karpenter"
    },
  )
}

# יוצר מסמך אמון שמאפשר רק לחשבון השירות של Karpenter לקבל את תפקיד הבקר.
data "aws_iam_policy_document" "controller_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.cluster.arn,
      ]
    }

    # מוודא שהאסימון מיועד לשירות STS.
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_hostpath}:aud"

      values = [
        "sts.amazonaws.com",
      ]
    }

    # מוודא שרק חשבון השירות המדויק של Karpenter יכול להשתמש בתפקיד.
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_hostpath}:sub"

      values = [
        "system:serviceaccount:${var.karpenter_namespace}:${var.karpenter_service_account_name}",
      ]
    }
  }
}

# יוצר תפקיד AWS עבור בקר Karpenter שרץ בתוך Kubernetes.
resource "aws_iam_role" "controller" {
  name               = "${var.name_prefix}-karpenter-controller"
  assume_role_policy = data.aws_iam_policy_document.controller_assume_role.json

  tags = merge(
    var.tags,
    {
      Name      = "${var.name_prefix}-karpenter-controller"
      Component = "karpenter-controller"
    },
  )
}

# יוצר מסמך אמון שמאפשר רק למכונות EC2 להשתמש בתפקיד מכונות Karpenter.
data "aws_iam_policy_document" "node_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "ec2.amazonaws.com",
      ]
    }
  }
}

# יוצר תפקיד נפרד עבור מכונות EC2 ש־Karpenter יקים בעת עומס.
resource "aws_iam_role" "node" {
  name               = "${var.name_prefix}-karpenter-node"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json

  tags = merge(
    var.tags,
    {
      Name      = "${var.name_prefix}-karpenter-node"
      Component = "karpenter-node"
    },
  )
}

# מחבר למכונות Karpenter את ההרשאות הבסיסיות להצטרפות לאשכול EKS.
resource "aws_iam_role_policy_attachment" "node_eks_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# מחבר למכונות Karpenter הרשאה למשיכת תמונות מ־ECR.
resource "aws_iam_role_policy_attachment" "node_ecr_pull" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

# מחבר למכונות Karpenter הרשאות רשת הנחוצות לתוסף EKS CNI.
resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# יוצר פרופיל מכונה קבוע עבור המכונות ש־Karpenter יקים.
resource "aws_iam_instance_profile" "node" {
  name = "${var.name_prefix}-karpenter-node"
  role = aws_iam_role.node.name
}

# מאפשר למכונות Karpenter להצטרף לאשכול כסוג מכונה של Linux.
resource "aws_eks_access_entry" "node" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.node.arn
  type          = "EC2_LINUX"

  # ממתין שספק הזהויות של האשכול יהיה מוכן.
  depends_on = [
    aws_iam_openid_connect_provider.cluster,
  ]
}

# מסמן את קבוצת האבטחה של האשכול כדי ש־Karpenter יוכל לגלות אותה.
resource "aws_ec2_tag" "cluster_security_group_discovery" {
  resource_id = var.cluster_security_group_id
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

# מגדיר את הרשאות בקר Karpenter לניהול מכונות ותחנות הפעלה ששייכות רק לאשכול זה.
data "aws_iam_policy_document" "controller" {
  statement {
    sid    = "AllowScopedEC2InstanceAccessActions"
    effect = "Allow"

    actions = [
      "ec2:CreateFleet",
      "ec2:RunInstances",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}::image/*",
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}::snapshot/*",
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:capacity-reservation/*",
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:placement-group/*",
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:security-group/*",
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:subnet/*",
    ]
  }

  statement {
    sid    = "AllowScopedEC2LaunchTemplateAccessActions"
    effect = "Allow"

    actions = [
      "ec2:CreateFleet",
      "ec2:RunInstances",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:launch-template/*",
    ]

    # מגביל שימוש לתבניות ש־Karpenter יצר עבור האשכול.
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}"

      values = [
        "owned",
      ]
    }

    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/karpenter.sh/nodepool"

      values = [
        "*",
      ]
    }
  }

  statement {
    sid    = "AllowScopedEC2InstanceActionsWithTags"
    effect = "Allow"

    actions = [
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate",
      "ec2:RunInstances",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:fleet/*",
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:instance/*",
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:launch-template/*",
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:network-interface/*",
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:spot-instances-request/*",
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:volume/*",
    ]

    # מוודא שכל משאב חדש מסומן כשייך לאשכול ול־NodePool.
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}"

      values = [
        "owned",
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/eks:eks-cluster-name"

      values = [
        var.cluster_name,
      ]
    }

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/karpenter.sh/nodepool"

      values = [
        "*",
      ]
    }
  }

  statement {
    sid    = "AllowScopedResourceCreationTagging"
    effect = "Allow"

    actions = [
      "ec2:CreateTags",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:fleet/*",
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:instance/*",
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:launch-template/*",
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:network-interface/*",
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:spot-instances-request/*",
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:volume/*",
    ]

    # מגביל תיוג רק בזמן יצירת משאב חדש.
    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"

      values = [
        "CreateFleet",
        "CreateLaunchTemplate",
        "RunInstances",
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}"

      values = [
        "owned",
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/eks:eks-cluster-name"

      values = [
        var.cluster_name,
      ]
    }

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/karpenter.sh/nodepool"

      values = [
        "*",
      ]
    }
  }

  statement {
    sid    = "AllowScopedDeletion"
    effect = "Allow"

    actions = [
      "ec2:DeleteLaunchTemplate",
      "ec2:RebootInstances",
      "ec2:TerminateInstances",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:instance/*",
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:launch-template/*",
    ]

    # מגביל מחיקה רק למשאבים שנוצרו על ידי Karpenter עבור האשכול.
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}"

      values = [
        "owned",
      ]
    }

    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/karpenter.sh/nodepool"

      values = [
        "*",
      ]
    }
  }

  statement {
    sid    = "AllowRegionalReadActions"
    effect = "Allow"

    actions = [
      "ec2:DescribeCapacityReservations",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribePlacementGroups",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeSubnets",
    ]

    resources = [
      "*",
    ]

    # מגביל את פעולות הקריאה לאזור AWS של סביבת הפיתוח.
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"

      values = [
        data.aws_region.current.region,
      ]
    }
  }

  statement {
    sid    = "AllowServiceParameterRead"
    effect = "Allow"

    actions = [
      "ssm:GetParameter",
    ]

    # מאפשר קריאת פרמטרים ציבוריים של AWS לבחירת תמונת מערכת מתאימה.
    resources = [
      "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.region}::parameter/aws/service/*",
    ]
  }

  statement {
    sid    = "AllowPricingRead"
    effect = "Allow"

    actions = [
      "pricing:GetProducts",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid    = "AllowNodeRolePass"
    effect = "Allow"

    actions = [
      "iam:PassRole",
    ]

    resources = [
      aws_iam_role.node.arn,
    ]

    # מונע העברת התפקיד לכל שירות שאינו EC2.
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"

      values = [
        "ec2.amazonaws.com",
      ]
    }
  }

  statement {
    sid    = "AllowNodeProfileRead"
    effect = "Allow"

    actions = [
      "iam:GetInstanceProfile",
    ]

    resources = [
      aws_iam_instance_profile.node.arn,
    ]
  }

  statement {
    sid    = "AllowClusterEndpointDiscovery"
    effect = "Allow"

    actions = [
      "eks:DescribeCluster",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:eks:${data.aws_region.current.region}:*:cluster/${var.cluster_name}",
    ]
  }
}

# מחבר את מדיניות הפעולות המצומצמת לתפקיד בקר Karpenter.
resource "aws_iam_role_policy" "controller" {
  name   = "${var.name_prefix}-karpenter-controller"
  role   = aws_iam_role.controller.id
  policy = data.aws_iam_policy_document.controller.json
}
