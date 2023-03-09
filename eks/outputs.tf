output "cluster" {
  description = "Cluster configuration"
  value       = aws_eks_cluster.this
}

output "cluster_sg_id" {
  description = "The id of the EKS cluster security group."
  value       = aws_security_group.cluster.id
}

output "worker_sg_id" {
  description = "The id of the EKS cluster security group."
  value       = aws_security_group.workers.id
}


output "aws_iam_openid_connect_provider_url" {
  description = "OpenId provider url"
  value       = aws_iam_openid_connect_provider.this.url
}

output "aws_iam_openid_connect_provider_arn" {
  description = "OpenId provider arn"
  value       = aws_iam_openid_connect_provider.this.arn
}

output "endpoint" {
  description = "EKS endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "app_role_arns" {
  description = "app role arns"
  value       = { for k, v in aws_iam_role.app : k => v.arn }
}