output "cluster_name" {
  value = module.eks.cluster_name
}

output "kubeconfig" {
  description = "Run this to set KUBECONFIG"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}
