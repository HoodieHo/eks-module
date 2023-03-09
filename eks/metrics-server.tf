resource "helm_release" "metrics_server" {
  depends_on = [
    aws_eks_node_group.workers
  ]
  name       = "metrics-server"
  namespace  = "kube-system"
  chart      = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  version    = var.metrics_server_chart_version
  wait       = length(var.node_groups) > 0 ? true : false

  dynamic "set" {
    for_each = var.metrics_server_settings
    content {
      name  = set.key
      value = set.value
    }
  }
}
