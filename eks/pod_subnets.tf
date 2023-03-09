data "aws_subnet" "secondary-eks" {
  for_each = toset(var.pod_subnets)
  id       = each.key
}

resource "aws_ec2_tag" "secondary-subnets" {
  for_each    = toset(var.pod_subnets)
  resource_id = each.key
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}

resource "null_resource" "create-eni" {
  depends_on = [aws_eks_cluster.this, null_resource.wait_for_cluster]
  for_each   = toset(var.pod_subnets)
  triggers = {
    endpoint     = aws_eks_cluster.this.endpoint
    cluster_name = aws_eks_cluster.this.id
    az           = data.aws_subnet.secondary-eks[each.key].availability_zone
    sg           = aws_security_group.workers.id
    subnet       = each.key
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        echo "${templatefile("${path.module}/templates/eniconfig.yaml", { az = data.aws_subnet.secondary-eks[each.key].availability_zone, sg = aws_security_group.workers.id, subnet = each.key })}" | kubectl --server=${self.triggers.endpoint} --insecure-skip-tls-verify=true --token=`aws eks get-token --cluster-name ${self.triggers.cluster_name} | jq -r '.status.token'` --kubeconfig=/dev/null apply -f -;
    EOT
  }
}
