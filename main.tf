module "eks" {
    source = "./eks"
    cluster_name = var.cluster_name
    vpc_id = var.vpc_id
    subnets = var.subnets
    node_groups = var.node_groups
    app_roles = var.app_roles
    tags = var.tags
}
