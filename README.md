# terraform-azuread-admin-units

Terraform module to manage Microsoft Entra ID (Azure AD) Administrative Units using a simple, manifest-driven approach.

## Features

- 📋 **Manifest-driven** — Define all admin units in a single tfvars file
- 🔄 **Declarative** — Add, modify, or remove admin units by updating the manifest
- ✅ **Validation** — Built-in checks for unique display names
- 🧩 **Simple** — Single input variable, no complex configuration required

## Usage

### Quick Start

```hcl
module "admin_units" {
  source = "github.com/4renwald/terraform-azuread-admin-units"

  admin_units = [
    {
      display_name = "IT Department"
      description  = "Administrative unit for IT department"
    },
    {
      display_name = "HR Department"
      description  = "Administrative unit for HR department"
      hidden_membership_enabled = true
    }
  ]
}
```

### Manifest-Driven Approach

Create a manifest file (e.g., `admin_units.tfvars`):

```hcl
admin_units = [
  {
    display_name = "IT Department"
    description  = "Administrative unit for IT department"
  },
  {
    display_name = "HR Department"
    description  = "Administrative unit for HR department"
    hidden_membership_enabled = true
  },
  {
    display_name = "Finance Department"
    description  = "Administrative unit for Finance department"
  }
]
```

Reference it in your Terraform configuration:

```hcl
variable "admin_units" {
  type = list(object({
    display_name              = string
    description               = optional(string)
    hidden_membership_enabled = optional(bool, false)
  }))
}

module "admin_units" {
  source = "github.com/4renwald/terraform-azuread-admin-units"

  admin_units = var.admin_units
}
```

Apply with:

```bash
terraform apply -var-file="admin_units.tfvars"
```

> [!TIP]
> The manifest file can be generated dynamically by external tooling, making it easy to integrate with GitOps workflows or configuration management systems.

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.0.0 |
| azuread | ~> 3.1.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `admin_units` | List of Administrative Units to create | `list(object)` | `[]` | no |

### Admin Unit Object

| Attribute | Description | Type | Default | Required |
|-----------|-------------|------|---------|:--------:|
| `display_name` | Display name of the Administrative Unit | `string` | — | yes |
| `description` | Description of the Administrative Unit | `string` | `null` | no |
| `hidden_membership_enabled` | Whether the membership list is hidden | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| `admin_units` | Map of created Administrative Units with all attributes |
| `admin_unit_ids` | Map of display names to object IDs |

## Authentication

The Azure AD provider supports multiple authentication methods:

**Azure CLI** (recommended for local development):
```bash
az login
terraform apply -var-file="admin_units.tfvars"
```

**Service Principal** (recommended for CI/CD):
```bash
export ARM_TENANT_ID="your-tenant-id"
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
```

## Examples

See the [examples/basic](examples/basic) directory for a complete working example.