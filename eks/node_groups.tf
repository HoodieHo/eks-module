################################################################################
# Workers security group
################################################################################
resource "aws_security_group" "workers" {
  name        = format("secgrp-%s-eks-worker", var.cluster_name)
  description = "Security group for nodes in the cluster."
  vpc_id      = var.vpc_id
  tags = merge(
    var.tags,
    {
      "Name"                                      = format("secgrp-%s-eks-worker", var.cluster_name)
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    },
  )
}

resource "aws_security_group_rule" "workers_egress" {
  description       = "Allow nodes egress."
  protocol          = "-1"
  security_group_id = aws_security_group.workers.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "workers_ingress_self" {
  description       = "All traffic between EKS cluster nodes"
  protocol          = "-1"
  security_group_id = aws_security_group.workers.id
  self              = true
  from_port         = 0
  to_port           = 65535
  type              = "ingress"
}

resource "aws_security_group_rule" "workers_ingress_cluster" {
  description              = "Allow workers pods to receive communication from the cluster control plane"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.workers.id
  source_security_group_id = aws_security_group.cluster.id
  from_port                = 10250
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "workers_ingress_cluster_https" {
  description              = "Allow pods running extension API servers on port 443 to receive communication from the cluster control plane"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.workers.id
  source_security_group_id = aws_security_group.cluster.id
  from_port                = 443
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "workers_ingress__metrics_cluster_https" {
  description              = "Allow metrics running extension API servers on port 8443 to receive communication from the cluster control plane."
  protocol                 = "tcp"
  security_group_id        = aws_security_group.workers.id
  source_security_group_id = aws_security_group.cluster.id
  from_port                = lookup(var.metrics_server_settings, "containerPort", 8443)
  to_port                  = lookup(var.metrics_server_settings, "containerPort", 8443)
  type                     = "ingress"
}

resource "aws_security_group_rule" "workers_ingress_custom_cidr" {
  count             = length(var.private_endpoint_cidrs) > 0 ? 1 : 0
  description       = "Allow access to workers when only private endpoint is set"
  protocol          = "tcp"
  security_group_id = aws_security_group.workers.id
  cidr_blocks       = var.private_endpoint_cidrs
  from_port         = 10250
  to_port           = 65535
  type              = "ingress"
}

################################################################################
# Worker instances launch template
################################################################################

data "aws_ami" "eks" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.this.version}-*"]
  }
}

locals {
  ami_params = [for group in var.node_groups :
    group.ami_id
    if contains(keys(group), "ami_id") && length(try(regexall("^ami-.*", group.ami_id), [])) == 0
  ]
}

data "aws_ssm_parameter" "ami" {
  for_each        = toset(local.ami_params)
  name            = each.key
  with_decryption = false
}

resource "aws_launch_template" "workers" {
  for_each               = local.workers
  name_prefix            = format("%s-%s", aws_eks_cluster.this.name, each.value.name)
  vpc_security_group_ids = flatten([aws_security_group.workers.id, try(each.value.additional_security_group_ids, [])])
  instance_type          = each.value.instance_type
  key_name               = try(each.value.key_name, null)
  ebs_optimized          = try(each.value.ebs_optimized, false)
  user_data              = base64encode(data.template_file.userdata[each.key].rendered)
  image_id               = try(contains(local.ami_params, each.value.ami_id) ? data.aws_ssm_parameter.ami[each.value.ami_id].value : each.value.ami_id, data.aws_ami.eks.id)

  monitoring {
    enabled = try(each.value.enable_monitoring, false)
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.block_metadata ? "required" : "optional"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = try(each.value.root_volume_size, 64)
      volume_type           = try(each.value.root_volume_type, "gp3")
      iops                  = try(each.value.root_iops, 0)
    }
  }

  lifecycle {
    create_before_destroy = true
  }
  tag_specifications {
    resource_type = "instance"

    tags = merge(var.tags, {
      Name = format("%s-%s", var.cluster_name, each.key)
    })
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(var.tags, {
      Name = format("%s-%s", var.cluster_name, each.key)
    })
  }

  tag_specifications {
    resource_type = "network-interface"

    tags = merge(var.tags, {
      Name = format("%s-%s", var.cluster_name, each.key)
    })
  }
}

################################################################################
# Node groups IAM role
################################################################################
resource "aws_iam_role" "workers" {
  name               = format("role-%s-worker", var.cluster_name)
  assume_role_policy = data.aws_iam_policy_document.workers_assume_role_policy.json
  path               = var.iam_path
  tags               = var.tags
  managed_policy_arns = compact([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
    "arn:aws:iam::aws:policy/AmazonElasticFileSystemReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])
}

resource "aws_iam_instance_profile" "workers" {
  name = format("%s-worker-role", var.cluster_name)
  role = aws_iam_role.workers.name
}

data "aws_iam_policy_document" "workers_assume_role_policy" {
  statement {
    sid = "EKSWorkerAssumeRole"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

################################################################################
# Userdata
################################################################################
locals {
  cluster_data = {
    cluster_endpoint           = aws_eks_cluster.this.endpoint
    certificate_authority_data = aws_eks_cluster.this.certificate_authority[0].data
    cluster_name               = aws_eks_cluster.this.name
  }
  workers = { for group in var.node_groups :
    group.name => group
  }
  autoscaler_enabled_tags = {
    "k8s.io/cluster-autoscaler/${aws_eks_cluster.this.name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled"                      = "true"
  }
}

data "external" "max-pods" {
  for_each = local.workers
  program  = ["bash", "${path.module}/templates/max-pods.sh"]

  query = {
    instance_type = each.value.instance_type
    cni_version   = lookup(var.addon_versions, "vpc-cni", "") == "" ? trimprefix(data.aws_eks_addon_version.vpc-cni[0].version, "v") : trimprefix(lookup(var.addon_versions, "vpc-cni"), "v")
    region        = data.aws_region.current.name
  }
}

data "template_file" "userdata" {
  for_each = local.workers
  template = file("${path.module}/templates/userdata.tpl")
  vars = merge({
    bootstrap_extra_args = format("--use-max-pods false %s", try(each.value.bootstrap_additional_options, ""))
    kubelet_extra_args   = format("--max-pods=%s %s", data.external.max-pods[each.key].result["max"], try(each.value.kubelet_extra_args, ""))
    dns_ip               = cidrhost(var.cluster_service_ipv4_cidr, 10)
  }, local.cluster_data, { node_group_name = join("-", [aws_eks_cluster.this.name, lookup(each.value, "name", each.key)]) })
}

################################################################################
# Amazon EKS managed node groups
################################################################################
resource "aws_eks_node_group" "workers" {
  for_each = local.workers
  launch_template {
    id      = aws_launch_template.workers[each.key].id
    version = aws_launch_template.workers[each.key].latest_version
  }
  cluster_name         = aws_eks_cluster.this.name
  node_group_name      = join("-", [aws_eks_cluster.this.name, each.key])
  node_role_arn        = aws_iam_role.workers.arn
  subnet_ids           = lookup(each.value, "subnets", var.subnets)
  force_update_version = try(lookup(each.value, "force"), null)

  scaling_config {
    desired_size = lookup(each.value, "asg_min_size")
    max_size     = lookup(each.value, "asg_max_size")
    min_size     = lookup(each.value, "asg_min_size")
  }

  dynamic "taint" {
    for_each = contains(keys(each.value), "taints") ? lookup(each.value, "taints") : []
    content {
      key    = taint.value["key"]
      value  = taint.value["value"]
      effect = taint.value["effect"]
    }
  }

  capacity_type = upper(lookup(each.value, "capacity_type", "ON_DEMAND"))

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  depends_on = [
    aws_eks_addon.vpc,
    kubernetes_config_map.aws_auth,
    aws_security_group_rule.workers_egress,
    aws_security_group_rule.workers_ingress_self,
    aws_security_group_rule.workers_ingress_cluster,
    aws_security_group_rule.workers_ingress_cluster_https,
    aws_security_group_rule.workers_ingress_custom_cidr,
  ]

  labels = lookup(each.value, "labels", {})
  tags = merge(
    var.tags,
    lookup(each.value, "tags", {}),
    {
      "Name" : join("-", [aws_eks_cluster.this.name, each.key])
    },
    lookup(each.value, "autoscaler", var.enable_cluster_autoscaler) ? local.autoscaler_enabled_tags : {}
  )

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}
