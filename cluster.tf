################################################################################
# Cluster CloudWatch group
################################################################################
resource "aws_cloudwatch_log_group" "cluster" {
  count             = length(var.cluster_enabled_log_types) > 0 ? 1 : 0
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cluster_log_retention_in_days
  tags              = var.tags
}

################################################################################
# Cluster security group
################################################################################
resource "aws_security_group" "cluster" {
  name        = format("secgrp-%s-eks", var.cluster_name)
  description = "Security Group for EKS cluster"
  vpc_id      = var.vpc_id
  tags = merge(
    var.tags,
    {
      "Name" = format("secgrp-%s-eks", var.cluster_name)
    },
  )
}

resource "aws_security_group_rule" "cluster_egress" {
  description       = "Allow all egress."
  protocol          = "-1"
  security_group_id = aws_security_group.cluster.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "cluster_ingress_worker_https" {
  description              = "Allow pods to communicate with the EKS cluster API"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.workers.id
  from_port                = 443
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster_metrics_ingress_cluster_https" {
  description              = "Allow metrics running extension API servers on port 8443 to receive communication from the cluster control plane"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.workers.id
  from_port                = lookup(var.metrics_server_settings, "containerPort", 8443)
  to_port                  = lookup(var.metrics_server_settings, "containerPort", 8443)
  type                     = "ingress"
}

resource "aws_security_group_rule" "private-access-sg" {
  for_each                 = var.cluster_endpoint_private_access && !var.cluster_endpoint_public_access ? toset(var.private_endpoint_sgs) : []
  description              = "Allow access to cluster when only private endpoint is set"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = each.key
  from_port                = 443
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "private-access-cidr" {
  count             = length(var.private_endpoint_cidrs) > 0 ? 1 : 0
  description       = "Allow access to cluster when only private endpoint is set"
  protocol          = "tcp"
  security_group_id = aws_security_group.cluster.id
  cidr_blocks       = var.private_endpoint_cidrs
  from_port         = 443
  to_port           = 443
  type              = "ingress"
}

################################################################################
# Cluster IAM role
################################################################################
data "aws_iam_policy_document" "cluster_assume_role_policy" {
  statement {
    sid = "EKSClusterAssumeRole"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = format("role-%s-eks", var.cluster_name)
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role_policy.json
  path               = var.iam_path
  tags               = var.tags
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  ]
}

################################################################################
# Amazon Elastic Kubernetes Service (EKS)
################################################################################
resource "aws_eks_cluster" "this" {
  name                      = var.cluster_name
  enabled_cluster_log_types = var.cluster_enabled_log_types
  role_arn                  = aws_iam_role.cluster.arn
  version                   = var.cluster_version

  vpc_config {
    security_group_ids      = [aws_security_group.cluster.id]
    subnet_ids              = var.subnets
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
  }

  kubernetes_network_config {
    service_ipv4_cidr = var.cluster_service_ipv4_cidr
  }

  timeouts {
    create = var.cluster_create_timeout
    delete = var.cluster_delete_timeout
  }

  dynamic "encryption_config" {
    for_each = var.kms_arn == "" ? [] : [1]
    content {
      provider {
        key_arn = var.kms_arn
      }
      resources = ["secrets"]
    }

  }

  depends_on = [
    aws_cloudwatch_log_group.cluster,
    aws_security_group_rule.cluster_egress,
    aws_security_group_rule.private-access-cidr,
    aws_security_group_rule.cluster_ingress_worker_https,
  ]
  tags = var.tags
}

resource "aws_ec2_tag" "cluster" {
  for_each    = toset(var.subnets)
  resource_id = each.key
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}

resource "null_resource" "wait_for_cluster" {
  depends_on = [
    aws_eks_cluster.this
  ]

  provisioner "local-exec" {
    command     = var.wait_for_cluster_cmd
    interpreter = var.wait_for_cluster_interpreter
    environment = {
      ENDPOINT = aws_eks_cluster.this.endpoint
    }
  }
}
