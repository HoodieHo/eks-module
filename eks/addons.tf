locals {
  vpc_cni_additional_configs = jsonencode(merge(
    try(lookup(var.addon_configs, "vpc-cni"), {}),
    length(var.pod_subnets) > 0 ?
    {
      env = {
        AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = "true"
        ENI_CONFIG_LABEL_DEF               = "failure-domain.beta.kubernetes.io/zone"
        ENABLE_PREFIX_DELEGATION           = "true"
        WARM_PREFIX_TARGET                 = "1"
      }
    } : {}
  ))
}

# VPC CNI
data "aws_eks_addon_version" "vpc-cni" {
  count              = lookup(var.addon_versions, "vpc-cni", "") == "" ? 1 : 0
  addon_name         = "vpc-cni"
  kubernetes_version = aws_eks_cluster.this.version
  most_recent        = true
}

resource "aws_eks_addon" "vpc" {
  depends_on               = [null_resource.wait_for_cluster]
  cluster_name             = aws_eks_cluster.this.name
  addon_name               = "vpc-cni"
  resolve_conflicts        = "OVERWRITE"
  addon_version            = lookup(var.addon_versions, "vpc-cni", "") == "" ? data.aws_eks_addon_version.vpc-cni[0].version : lookup(var.addon_versions, "vpc-cni")
  tags                     = var.tags
  service_account_role_arn = aws_iam_role.vpc-cni.arn
  configuration_values     = length(local.vpc_cni_additional_configs) > 2 ? local.vpc_cni_additional_configs : null # 2 == "{}"
}

resource "aws_iam_role" "vpc-cni" {
  name               = "role-${var.cluster_name}-vpc-cni"
  assume_role_policy = data.aws_iam_policy_document.vpc-cni-assume.json
  tags               = var.tags
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ]
}

data "aws_iam_policy_document" "vpc-cni-assume" {
  statement {
    sid = "AutoScalerAssume"
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
        format("system:serviceaccount:kube-system:aws-node")
      ]
    }
  }
}

# COREDNS
data "aws_eks_addon_version" "core-dns" {
  count              = lookup(var.addon_versions, "coredns", "") == "" ? 1 : 0
  addon_name         = "coredns"
  kubernetes_version = aws_eks_cluster.this.version
  most_recent        = true
}


resource "aws_eks_addon" "coredns" {
  depends_on           = [null_resource.wait_for_cluster, aws_eks_node_group.workers]
  cluster_name         = aws_eks_cluster.this.name
  addon_name           = "coredns"
  resolve_conflicts    = "OVERWRITE"
  addon_version        = lookup(var.addon_versions, "coredns", "") == "" ? data.aws_eks_addon_version.core-dns[0].version : lookup(var.addon_versions, "coredns")
  tags                 = var.tags
  configuration_values = lookup(var.addon_configs, "coredns", null)
}

# KUBEPROXY
data "aws_eks_addon_version" "kube-proxy" {
  count              = lookup(var.addon_versions, "kube-proxy", "") == "" ? 1 : 0
  addon_name         = "kube-proxy"
  kubernetes_version = aws_eks_cluster.this.version
  most_recent        = true
}


resource "aws_eks_addon" "kubeproxy" {
  depends_on           = [null_resource.wait_for_cluster, aws_eks_node_group.workers]
  cluster_name         = aws_eks_cluster.this.name
  addon_name           = "kube-proxy"
  resolve_conflicts    = "OVERWRITE"
  addon_version        = lookup(var.addon_versions, "kube-proxy", "") == "" ? data.aws_eks_addon_version.kube-proxy[0].version : lookup(var.addon_versions, "kube-proxy")
  tags                 = var.tags
  configuration_values = lookup(var.addon_configs, "kube-proxy", null)
}

# EBS
data "aws_eks_addon_version" "ebs" {
  count              = lookup(var.addon_versions, "aws-ebs-csi-driver", "") == "" ? 1 : 0
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = aws_eks_cluster.this.version
  most_recent        = true
}


data "aws_iam_policy_document" "ebs-csi-assume" {
  statement {
    sid = "AutoScalerAssume"
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
        format("system:serviceaccount:kube-system:ebs-csi-controller-sa")
      ]
    }
  }
}

resource "aws_iam_role" "ebs-csi" {
  name               = "role-${var.cluster_name}-ebs-csi"
  assume_role_policy = data.aws_iam_policy_document.ebs-csi-assume.json
  tags               = var.tags
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  ]
}

resource "aws_eks_addon" "ebs" {
  depends_on               = [null_resource.wait_for_cluster, aws_eks_node_group.workers]
  cluster_name             = aws_eks_cluster.this.name
  addon_name               = "aws-ebs-csi-driver"
  resolve_conflicts        = "OVERWRITE"
  addon_version            = lookup(var.addon_versions, "aws-ebs-csi-driver", "") == "" ? data.aws_eks_addon_version.ebs[0].version : lookup(var.addon_versions, "aws-ebs-csi-driver")
  tags                     = var.tags
  service_account_role_arn = aws_iam_role.ebs-csi.arn
  configuration_values     = lookup(var.addon_configs, "aws-ebs-csi-driver", null)
}