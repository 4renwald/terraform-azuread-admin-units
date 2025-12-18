terraform {
  required_version = ">= 1.0.0"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.1.0"
    }
  }
}

provider "azuread" {
  # Authentication can be configured via environment variables:
  # - ARM_TENANT_ID
  # - ARM_CLIENT_ID
  # - ARM_CLIENT_SECRET (for service principal)
  # Or use Azure CLI authentication
}

module "admin_units" {
  source = "../../"

  admin_units = var.admin_units
}
