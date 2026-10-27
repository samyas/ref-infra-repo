# ref-infra

Terraform base of the platform: namespaces, resource quotas, Pod Security and a
least-privilege deployment identity. Reference repo (Phase 3 of the DevOps final
project), meant to be reused for future projects.

## What it creates (per entry of `var.environments`)

| Resource | Purpose |
|---|---|
| Namespace | Isolated space, with the `restricted` Pod Security level enforced |
| ResourceQuota | Caps Pods, CPU requests and memory requests |
| ServiceAccount `deployer` | Identity used to deploy |
| Role + RoleBinding | Rights limited to that namespace, no `delete` |

Terraform stops at the platform. The content of the namespaces is managed by
Argo CD from `ref-gitops`.

## Files

| File | Role |
|---|---|
| `versions.tf` | Terraform and provider version constraints |
| `providers.tf` | Connection to the cluster through the kubeconfig |
| `variables.tf` | Inputs: context, environments and quotas, security level |
| `main.tf` | The resources, driven by `for_each` |
| `outputs.tf` | Namespaces and ServiceAccounts created |
| `terraform.tfvars.example` | Template for local overrides |

## Prerequisites

- A running cluster with Calico as the CNI (needed later for NetworkPolicies)
- `kubectl get nodes` works and the context matches `kube_context` (default `minikube`)
- Terraform >= 1.5

## Usage

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

## Verify

```bash
kubectl get ns dev prod --show-labels                      # pod-security labels present
kubectl describe resourcequota quota -n dev                # quota applied
kubectl auth can-i create deployments -n dev \
  --as=system:serviceaccount:dev:deployer                  # yes
kubectl auth can-i delete pods -n dev \
  --as=system:serviceaccount:dev:deployer                  # no
kubectl auth can-i get pods -n prod \
  --as=system:serviceaccount:dev:deployer                  # no (other namespace)
```

## Adding a namespace

Add one entry to `environments` (in `variables.tf` or a local `terraform.tfvars`),
then plan and apply. Namespaces are per environment, so a new app deployed to
`dev` and `prod` needs no change here. Add an entry only if an app needs its own
isolated namespace, for example `staging` or `myapp-dev`.

## Notes

- **State stays out of Git.** `.gitignore` excludes `*.tfstate*`. Back it up some
  other way, or move to a remote backend later.
- **Commit `.terraform.lock.hcl`** so everyone uses the same provider build.
- **Do not label the `monitoring` namespace as `restricted`.** The Prometheus
  node exporter needs privileges that this level forbids. Only the application
  namespaces get `restricted`.
- **Pods need resource requests.** With a quota on requests, a Pod that declares
  none is rejected. The Helm chart must set `resources.requests`.
- If `terraform validate` rejects a resource name (`_v1` suffix), check the
  documentation of the provider version you installed.
