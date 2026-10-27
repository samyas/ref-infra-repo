output "namespaces" {
  description = "Namespaces created by this configuration."
  value       = sort(keys(kubernetes_namespace_v1.env))
}

output "deployer_service_accounts" {
  description = "Deployment ServiceAccount per namespace."
  value = {
    for env, sa in kubernetes_service_account_v1.deployer :
    env => "system:serviceaccount:${env}:${sa.metadata[0].name}"
  }
}
