variable "kubeconfig_path" {
  description = "Path to the kubeconfig file used to reach the cluster."
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "kubectl context to use (check with: kubectl config get-contexts)."
  type        = string
  default     = "minikube"
}

# One entry per namespace to create. Adding an environment (or a dedicated
# namespace for one app) is a single new entry here: the resources in main.tf
# are all driven by this map with for_each.
variable "environments" {
  description = "Namespaces to create, with the resource quota applied to each."
  type = map(object({
    pods            = string # max number of Pods
    requests_cpu    = string # total CPU requests allowed
    requests_memory = string # total memory requests allowed
  }))
  default = {
    dev = {
      pods            = "10"
      requests_cpu    = "2"
      requests_memory = "2Gi"
    }
    prod = {
      pods            = "10"
      requests_cpu    = "2"
      requests_memory = "2Gi"
    }
  }
}

variable "pod_security_level" {
  description = "Pod Security Standard enforced on every namespace."
  type        = string
  default     = "restricted"

  validation {
    condition     = contains(["privileged", "baseline", "restricted"], var.pod_security_level)
    error_message = "pod_security_level must be privileged, baseline or restricted."
  }
}

variable "deployer_name" {
  description = "Name of the ServiceAccount, Role and RoleBinding used for deployments."
  type        = string
  default     = "deployer"
}
