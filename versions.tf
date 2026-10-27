# Pin Terraform and provider versions so every run behaves the same way.
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30" # check the registry for the latest 2.x release
    }
  }
}
