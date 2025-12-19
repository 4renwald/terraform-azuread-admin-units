terraform {
  required_version = ">= 1.0.0"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.1.0"
    }
    msgraph = {
      source  = "microsoft/msgraph"
      version = "~> 0.2.0"
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

provider "msgraph" {
  # Uses same authentication as azuread provider
  # Requires additional API permissions:
  # - RoleEligibilitySchedule.ReadWrite.Directory
  # - RoleManagement.ReadWrite.Directory
}

module "admin_units" {
  source = "../../"

  admin_units = var.admin_units
}
