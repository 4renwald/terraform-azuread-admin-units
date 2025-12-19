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
