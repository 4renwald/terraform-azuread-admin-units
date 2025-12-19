# terraform-azuread-admin-units

Terraform module to manage Microsoft Entra ID (Azure AD) Administrative Units with full support for groups, members, and **PIM eligible/active role assignments**.

## Features

- 📋 **Manifest-driven** — Define all admin units in a single tfvars file
- 🔄 **Declarative** — Add, modify, or remove admin units by updating the manifest
- 👥 **Groups & Members** — Create security groups and manage user/group membership within AUs
- 🔐 **PIM Support** — Both eligible and active role assignments scoped to AUs
- ⏱️ **Scheduling** — Permanent or time-bound role assignments with ISO 8601 dates
- ✅ **Validation** — Built-in checks for unique names, valid assignment types, and schedule rules
- 🏗️ **Hybrid Architecture** — Uses `azuread` + `msgraph` providers for complete functionality

## Architecture

This module uses a **hybrid provider approach**:

| Provider | Resources | Purpose |
|----------|-----------|---------|
| `hashicorp/azuread` | Administrative Units, Groups, Members, Active Role Assignments | Mature, typed resources |
| `microsoft/msgraph` | PIM Eligible Role Assignments | Direct Graph API access for PIM |

> See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for detailed architecture documentation.

## Usage

### Quick Start

**1. Create a manifest file** (`admin_units.tfvars`):

```hcl
admin_units = [
  {
    display_name = "IT Department"
    description  = "Administrative unit for IT department"

    groups = [
      {
        display_name = "GRP_IT_Admins"
        description  = "IT Administrators"
      }
    ]

    members = {
      user_principal_names = ["user1@contoso.com", "user2@contoso.com"]
    }

    role_assignments = [
      {
        role_display_name = "User Administrator"
        assignment_type   = "eligible"  # PIM eligible
        principal_names   = ["admin@contoso.com"]
        schedule = {
          type = "permanent"
        }
        justification = "IT Admin role for department management"
      }
    ]
  }
]
```

**2. Create your Terraform configuration** (`main.tf`):

```hcl
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

provider "azuread" {}
provider "msgraph" {}

module "admin_units" {
  source = "github.com/4renwald/terraform-azuread-admin-units"

  admin_units = var.admin_units
}
```

**variables.tf**:

```hcl
variable "admin_units" {
  description = "List of Administrative Units to create"
  type        = any
  default     = []
}
```

**3. Apply with the manifest**:

```bash
terraform apply -var-file="admin_units.tfvars"
```

### Complete Example with All Features

**Manifest file** (`manifest.tfvars`):

```hcl
admin_units = [
  {
    display_name              = "Engineering"
    description               = "Engineering department administrative unit"
    hidden_membership_enabled = false

    # Create security groups within this AU
    groups = [
      {
        display_name = "GRP_ENG_DevOps"
        description  = "DevOps engineers"
      },
      {
        display_name = "GRP_ENG_Platform"
        description  = "Platform team"
      }
    ]

    # Add members to the AU
    members = {
      user_principal_names = [
        "developer1@contoso.com",
        "developer2@contoso.com"
      ]
      group_display_names = ["GRP_ENG_DevOps"]  # Reference created groups
    }

    # Scoped role assignments
    role_assignments = [
      # PIM Eligible - User activates when needed
      {
        role_display_name = "User Administrator"
        assignment_type   = "eligible"
        principal_names   = ["eng_lead@contoso.com"]
        schedule = {
          type       = "temporary"
          start_date = "2025-01-01T00:00:00Z"
          end_date   = "2025-12-31T23:59:59Z"
        }
        justification = "Temporary eligible access for 2025"
      },
      # Active - Immediate permanent access
      {
        role_display_name = "Groups Administrator"
        assignment_type   = "active"
        principal_names   = ["groups_admin@contoso.com"]
        justification     = "Permanent group management access"
      }
    ]
  }
]
```

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.0.0 |
| azuread | ~> 3.1.0 |
| msgraph | ~> 0.2.0 |

### Licensing

⚠️ **PIM eligible assignments require Microsoft Entra ID P2 or Microsoft Entra ID Governance license.**

### API Permissions

The service principal or user running Terraform needs these permissions:

| Permission | Type | Purpose |
|------------|------|---------|
| `AdministrativeUnit.ReadWrite.All` | Application | Create/manage AUs |
| `Directory.ReadWrite.All` | Application | Groups, members, roles |
| `User.Read.All` | Application | User lookups by UPN |
| `RoleEligibilitySchedule.ReadWrite.Directory` | Application | PIM eligible assignments |
| `RoleManagement.ReadWrite.Directory` | Application | Role assignments |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `admin_units` | List of Administrative Units to create | `list(object)` | `[]` | no |

### Admin Unit Object

| Attribute | Description | Type | Default | Required |
|-----------|-------------|------|---------|:--------:|
| `display_name` | Display name of the Administrative Unit | `string` | — | yes |
| `description` | Description of the Administrative Unit | `string` | `null` | no |
| `hidden_membership_enabled` | Hide membership from non-admins | `bool` | `false` | no |
| `groups` | List of security groups to create | `list(object)` | `[]` | no |
| `members` | Users and groups to add as members | `object` | `{}` | no |
| `role_assignments` | Scoped role assignments | `list(object)` | `[]` | no |

### Group Object

| Attribute | Description | Type | Default | Required |
|-----------|-------------|------|---------|:--------:|
| `display_name` | Display name of the group | `string` | — | yes |
| `description` | Description of the group | `string` | `null` | no |

### Members Object

| Attribute | Description | Type | Default |
|-----------|-------------|------|---------|
| `user_principal_names` | List of user UPNs to add | `list(string)` | `[]` |
| `group_display_names` | List of group names (created in `groups`) | `list(string)` | `[]` |

### Role Assignment Object

| Attribute | Description | Type | Default | Required |
|-----------|-------------|------|---------|:--------:|
| `role_display_name` | Directory role name (e.g., "User Administrator") | `string` | — | yes |
| `assignment_type` | `"eligible"` (PIM) or `"active"` (permanent) | `string` | — | yes |
| `principal_names` | List of user UPNs to assign the role | `list(string)` | — | yes |
| `schedule` | Schedule configuration | `object` | `{type="permanent"}` | no |
| `justification` | Reason for assignment | `string` | `"Managed by Terraform"` | no |

### Schedule Object

| Attribute | Description | Type | Default |
|-----------|-------------|------|---------|
| `type` | `"permanent"` or `"temporary"` | `string` | `"permanent"` |
| `start_date` | Start date (ISO 8601) | `string` | Current time |
| `end_date` | End date (ISO 8601, required if temporary) | `string` | — |

## Outputs

| Name | Description |
|------|-------------|
| `admin_units` | Map of created Administrative Units with full attributes |
| `admin_unit_ids` | Map of AU display names to object IDs |
| `groups` | Map of created groups with attributes |
| `group_ids` | Map of group keys to object IDs |
| `user_members` | Map of user membership records |
| `group_members` | Map of group membership records |
| `active_role_assignments` | Map of active (permanent) role assignments |
| `eligible_role_assignments` | Map of PIM eligible role assignments |
| `summary` | Summary counts of all created resources |

## Validation Rules

The module enforces these validation rules:

1. **Unique display names** — Each admin unit must have a unique `display_name`
2. **Valid assignment type** — `assignment_type` must be `"eligible"` or `"active"`
3. **Temporary schedule end date** — If `schedule.type = "temporary"`, `end_date` is required

## Testing

Run tests with mock providers (no Azure credentials required):

```bash
terraform test
```

## Multi-Tenant / Multi-Stage Deployment

For environments with multiple tenants or stages (dev, preprod, prod), use separate manifest files:

```
manifests/
├── tenant-a/
│   ├── dev.tfvars
│   ├── preprod.tfvars
│   └── prod.tfvars
└── tenant-b/
    ├── dev.tfvars
    └── prod.tfvars
```

Apply with:

```bash
terraform apply -var-file="manifests/tenant-a/dev.tfvars"
```

## Authentication

### Azure CLI (Development)

```bash
az login
terraform apply -var-file="manifest.tfvars"
```

### Service Principal (CI/CD)

```bash
export ARM_TENANT_ID="your-tenant-id"
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
terraform apply -var-file="manifest.tfvars"
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Run `terraform fmt` and `terraform test`
4. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details.
