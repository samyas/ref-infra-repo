# ---------------------------------------------------------------------------
# Platform base: one namespace per entry of var.environments, each with
#   - the Pod Security level enforced,
#   - a resource quota,
#   - a deployment ServiceAccount limited to that namespace (least privilege).
# Terraform stops at the platform: what runs INSIDE the namespaces is managed
# by Argo CD (GitOps), not by this repo.
# ---------------------------------------------------------------------------

# 1. Namespaces ---------------------------------------------------------------
# The pod-security labels make the Kubernetes API server reject any Pod that
# does not meet the chosen level (enforce), and also report violations (audit, warn).
resource "kubernetes_namespace_v1" "env" {
  for_each = var.environments

  metadata {
    name = each.key
    labels = {
      "pod-security.kubernetes.io/enforce" = var.pod_security_level
      "pod-security.kubernetes.io/audit"   = var.pod_security_level
      "pod-security.kubernetes.io/warn"    = var.pod_security_level
      "app.kubernetes.io/managed-by"       = "terraform"
    }
  }
}

# 2. Resource quotas ----------------------------------------------------------
# Caps what one namespace can consume so a bad deployment cannot starve the
# whole cluster. Pods must declare resource requests (the Helm chart does).
resource "kubernetes_resource_quota_v1" "quota" {
  for_each = var.environments

  metadata {
    name      = "quota"
    namespace = kubernetes_namespace_v1.env[each.key].metadata[0].name
  }

  spec {
    hard = {
      "pods"            = each.value.pods
      "requests.cpu"    = each.value.requests_cpu
      "requests.memory" = each.value.requests_memory
    }
  }
}

# 3. Deployment identity ------------------------------------------------------
resource "kubernetes_service_account_v1" "deployer" {
  for_each = var.environments

  metadata {
    name      = var.deployer_name
    namespace = kubernetes_namespace_v1.env[each.key].metadata[0].name
  }
}

# A Role (not a ClusterRole) only works inside its own namespace.
# No "delete" verb on purpose: the deployer can roll out, not destroy.
resource "kubernetes_role_v1" "deployer" {
  for_each = var.environments

  metadata {
    name      = var.deployer_name
    namespace = kubernetes_namespace_v1.env[each.key].metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "configmaps"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }

  # Read-only: needed to follow a rollout, nothing more.
  rule {
    api_groups = ["apps"]
    resources  = ["replicasets"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding_v1" "deployer" {
  for_each = var.environments

  metadata {
    name      = var.deployer_name
    namespace = kubernetes_namespace_v1.env[each.key].metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.deployer[each.key].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.deployer[each.key].metadata[0].name
    namespace = kubernetes_namespace_v1.env[each.key].metadata[0].name
  }
}
