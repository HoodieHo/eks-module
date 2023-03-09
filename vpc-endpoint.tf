resource "aws_security_group" "sg_vpc_endpoint" {
  name        = format("secgroup-%s-ecr-endpoint", var.cluster_name)
  description = "ECR vpc endpoint security group"
  vpc_id      = data.aws_vpc.this.id
  tags        = var.tags
}

resource "aws_security_group_rule" "vpce_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.this.cidr_block]
  security_group_id = aws_security_group.sg_vpc_endpoint.id
}

resource "aws_security_group_rule" "additional_cidrs" {
  count             = length(var.private_endpoint_cidrs) > 0 ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.private_endpoint_cidrs
  security_group_id = aws_security_group.sg_vpc_endpoint.id
}

resource "aws_vpc_endpoint" "dkr" {
  vpc_id             = data.aws_vpc.this.id
  service_name       = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  security_group_ids = [aws_security_group.sg_vpc_endpoint.id]
  vpc_endpoint_type  = "Interface"
  subnet_ids         = var.subnets
  tags               = var.tags
}

resource "aws_vpc_endpoint" "api" {
  vpc_id             = data.aws_vpc.this.id
  service_name       = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  security_group_ids = [aws_security_group.sg_vpc_endpoint.id]
  vpc_endpoint_type  = "Interface"
  subnet_ids         = var.subnets
  tags               = var.tags
}
