resource "aws_iam_role" "alb" {
  count              = var.deploy_alb_ingress ? 1 : 0
  name               = format("role-%s-alb-ingress", var.cluster_name)
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.alb-assume[0].json
  tags               = var.tags
}

data "aws_iam_policy_document" "alb" {
  count = var.deploy_alb_ingress ? 1 : 0

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]
    actions   = ["iam:CreateServiceLinkedRole"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["elasticloadbalancing.amazonaws.com"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeTags",
      "ec2:GetCoipPoolUsage",
      "ec2:DescribeCoipPools",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeTags",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "cognito-idp:DescribeUserPoolClient",
      "acm:ListCertificates",
      "acm:DescribeCertificate",
      "iam:ListServerCertificates",
      "iam:GetServerCertificate",
      "waf-regional:GetWebACL",
      "waf-regional:GetWebACLForResource",
      "waf-regional:AssociateWebACL",
      "waf-regional:DisassociateWebACL",
      "wafv2:GetWebACL",
      "wafv2:GetWebACLForResource",
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL",
      "shield:GetSubscriptionState",
      "shield:DescribeProtection",
      "shield:CreateProtection",
      "shield:DeleteProtection",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:CreateSecurityGroup"]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:security-group/*"]
    actions   = ["ec2:CreateTags"]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["CreateSecurityGroup"]
    }

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:security-group/*"]

    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["true"]
    }

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DeleteSecurityGroup",
    ]

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateTargetGroup",
    ]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:DeleteRule",
    ]
  }

  statement {
    sid    = ""
    effect = "Allow"

    resources = [
      "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*",
    ]

    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags",
    ]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["true"]
    }

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    sid    = ""
    effect = "Allow"

    resources = [
      "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*",
    ]

    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:DeleteTargetGroup",
    ]

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"]

    actions = [
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "elasticloadbalancing:SetWebAcl",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:ModifyRule",
    ]
  }
}

resource "aws_iam_role_policy" "alb" {
  count  = var.deploy_alb_ingress ? 1 : 0
  name   = format("%s-external-dns", var.cluster_name)
  role   = aws_iam_role.alb[0].name
  policy = data.aws_iam_policy_document.alb[0].json
}

data "aws_iam_policy_document" "alb-assume" {
  count = var.deploy_alb_ingress ? 1 : 0
  statement {
    sid = "ExternalDNSAssume"
    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }
    condition {
      test     = "StringEquals"
      variable = format("%s:sub", replace(aws_iam_openid_connect_provider.this.url, "https://", ""))
      values = [
        "system:serviceaccount:kube-system:aws-load-balancer-controller"
      ]
    }
  }
}

resource "aws_security_group" "alb" {
  count       = var.deploy_alb_ingress ? 1 : 0
  name        = format("secgrp-%s-alb-ingress", var.cluster_name)
  description = "Security Group for ALB"
  vpc_id      = var.vpc_id
  tags = merge(
    var.tags,
    {
      "Name" = format("secgrp-%s-alb-ingress", var.cluster_name)
    },
  )
}

resource "aws_security_group_rule" "alb_egress" {
  count             = var.deploy_alb_ingress ? 1 : 0
  description       = "Allow all egress."
  protocol          = "-1"
  security_group_id = aws_security_group.alb[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  type              = "egress"
}

locals {
  alb_allowed_cidrs = try(coalescelist(var.alb_allowed_cidrs, var.private_endpoint_cidrs), [])
}

resource "aws_security_group_rule" "alb-https-private-access-cidr" {
  count             = var.deploy_alb_ingress && length(local.alb_allowed_cidrs) > 0 ? 1 : 0
  description       = "Allow access to alb"
  protocol          = "tcp"
  security_group_id = aws_security_group.alb[0].id
  cidr_blocks       = local.alb_allowed_cidrs
  from_port         = 443
  to_port           = 443
  type              = "ingress"
}

resource "aws_security_group_rule" "alb-http-private-access-cidr" {
  count             = var.deploy_alb_ingress && length(local.alb_allowed_cidrs) > 0 ? 1 : 0
  description       = "Allow access to alb"
  protocol          = "tcp"
  security_group_id = aws_security_group.alb[0].id
  cidr_blocks       = local.alb_allowed_cidrs
  from_port         = 80
  to_port           = 80
  type              = "ingress"
}

resource "aws_security_group_rule" "alb-cluster-permissions" {
  count                    = var.deploy_alb_ingress ? 1 : 0
  description              = "Allow cluster to interact with admission controller"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.workers.id
  source_security_group_id = aws_security_group.cluster.id
  from_port                = 9443
  to_port                  = 9443
  type                     = "ingress"
}

resource "aws_security_group_rule" "alb-worker-permissions" {
  count                    = var.deploy_alb_ingress ? 1 : 0
  description              = "Allow cluster to interact with admission controller"
  protocol                 = "-1"
  security_group_id        = aws_security_group.workers.id
  source_security_group_id = aws_security_group.alb[0].id
  from_port                = 0
  to_port                  = 0
  type                     = "ingress"
}

resource "aws_ec2_tag" "alb-subnet-tags" {
  for_each    = toset(var.subnets)
  resource_id = each.key
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

resource "helm_release" "alb" {
  count = var.deploy_alb_ingress ? 1 : 0
  depends_on = [
    # Create and Destroy depending on the worker nodes existance
    aws_eks_node_group.workers,
    # Keep addons available during destroy
    aws_eks_addon.vpc,
    # This is required to interact with AWS ALB during destroy
    aws_iam_role_policy.alb,
    # This rule is required to interact with AWS ALB API
    aws_security_group_rule.alb-worker-permissions,
    aws_security_group_rule.alb-cluster-permissions,
  ]
  name       = "alb"
  repository = "https://aws.github.io/eks-charts"
  namespace  = "kube-system"
  chart      = "aws-load-balancer-controller"
  version    = var.alb_ingress_chart_version
  set {
    name  = "clusterName"
    value = aws_eks_cluster.this.id
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.alb[0].arn
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  set {
    name  = "ingressClass"
    value = "alb"
  }
  set {
    name  = "backendSecurityGroup"
    value = aws_security_group.alb[0].id
  }
  set {
    name  = "vpcId"
    value = var.vpc_id
  }
}

resource "kubernetes_ingress_v1" "ingress" {
  count = var.deploy_alb_ingress && var.create_default_ingress ? 1 : 0

  depends_on = [
    aws_eks_node_group.workers,
    helm_release.alb
  ]

  metadata {
    name      = "default-ingress"
    namespace = "kube-system"

    annotations = {
      "alb.ingress.kubernetes.io/actions.response-404"     = "{\"type\":\"fixed-response\",\"fixedResponseConfig\":{\"contentType\":\"text/plain\",\"statusCode\":\"404\",\"messageBody\":\"Not found\"}}\n"
      "alb.ingress.kubernetes.io/group.name"               = "common"
      "alb.ingress.kubernetes.io/load-balancer-name"       = substr("alb-${var.cluster_name}-ingress", 0, 32) # LB name can't be longer than 32 characters
      "alb.ingress.kubernetes.io/scheme"                   = "internal"
      "alb.ingress.kubernetes.io/security-groups"          = aws_security_group.alb[0].id
      "alb.ingress.kubernetes.io/tags"                     = join(",", [for key, value in var.tags : "${key}=${value}"])
      "alb.ingress.kubernetes.io/target-type"              = "ip"
      "alb.ingress.kubernetes.io/group.order"              = "1000"
      "kubernetes.io/ingress.class"                        = "alb"
      "alb.ingress.kubernetes.io/load-balancer-attributes" = join(",", [for key, value in var.alb_custom_attrs : "${key}=${value}"])
    }
  }

  spec {
    rule {
      http {
        path {
          path = "/"
          backend {
            service {
              name = "response-404"
              port {
                name = "use-annotation"
              }
            }
          }
        }
      }
    }
  }
}

