# Talks to the cluster described in your kubeconfig (Minikube by default).
# Nothing secret lives in this file: credentials stay in ~/.kube/config.
provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kube_context
}
