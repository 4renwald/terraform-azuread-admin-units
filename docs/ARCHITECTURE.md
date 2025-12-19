# Architecture Documentation

This document provides detailed architectural documentation for the `terraform-azuread-admin-units` module.

## Overview

This Terraform module implements a **hybrid provider architecture** to manage Microsoft Entra ID (Azure AD) Administrative Units with full PIM (Privileged Identity Management) support.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     terraform-azuread-admin-units                           │
├─────────────────────────────────────────────────────────────────────────────┤
│  INPUT: admin_units (list)                                                  │
│    └── Manifest-driven configuration via .tfvars files                      │
├─────────────────────────────────────────────────────────────────────────────┤
│  PROCESSING: locals.tf                                                      │
│    └── Flattening nested structures into for_each-compatible maps           │
├─────────────────────────────────────────────────────────────────────────────┤
│  PROVIDERS                                                                  │
│  ┌─────────────────────────────────┐  ┌─────────────────────────────────┐  │
│  │  hashicorp/azuread (~> 3.1.0)   │  │  microsoft/msgraph (~> 0.2.0)   │  │
│  │  ├── Administrative Units       │  │  └── PIM Eligible Assignments   │  │
│  │  ├── Groups                     │  │      (Graph API direct access)  │  │
│  │  ├── Members                    │  └─────────────────────────────────┘  │
│  │  ├── Directory Roles            │                                       │
│  │  └── Active Role Assignments    │                                       │
│  └─────────────────────────────────┘                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│  OUTPUT: Structured maps of all created resources + summary counts          │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Design Decisions

### Why Hybrid Providers?

| Approach | Pros | Cons |
|----------|------|------|
| **azuread only** | Mature, stable, well-documented, typed resources | No PIM eligible support |
| **msgraph only** | Full Graph API access | Immature (v0.2.0), generic resources, less type safety |
| **Hybrid** | Best of both worlds | Slightly more complex provider configuration |

**Decision**: Use `azuread` for all standard resources and `msgraph` only for PIM eligible assignments, which are not supported by the azuread provider.

### Why `display_name` as Resource Key?

Resources are keyed by `display_name` instead of generated IDs:

```hcl
for_each = { for au in var.admin_units : au.display_name => au }
```

**Rationale**:
- Human-readable resource addresses in Terraform state and plans
- Intuitive `terraform state` commands
- Clear identification in outputs and logs

**Trade-off**: Renaming an admin unit will destroy and recreate it.

### Why Manifest-Driven Input?

A single `admin_units` list variable with nested objects:

**Rationale**:
- Lists in `.tfvars` files are more maintainable than maps
- Better diff-friendly changes in version control
- Single source of truth for all AU configuration
- Easy to generate dynamically from external tools

## File Structure

```
terraform-azuread-admin-units/
├── versions.tf      # Provider requirements (azuread + msgraph)
├── variables.tf     # Single admin_units variable with validations
├── locals.tf        # Flattening logic for nested structures
├── data.tf          # User lookups + directory role activation
├── main.tf          # Administrative Units (azuread)
├── groups.tf        # Security groups within AUs (azuread)
├── members.tf       # User and group members (azuread)
├── pim.tf           # Active + PIM eligible role assignments
├── outputs.tf       # All resource outputs + summary
├── tests/           # Native Terraform tests with mock providers
│   └── admin_units.tftest.hcl
├── examples/
│   └── basic/       # Complete working example
└── docs/
    └── ARCHITECTURE.md  # This file
```

## Data Flow

### 1. Input Processing

```
admin_units (list)
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  locals.tf - Flattening                                     │
│                                                             │
│  groups_flat:          "AU_Name/Group_Name" => {...}        │
│  user_members_flat:    "AU_Name/user@domain.com" => {...}   │
│  group_members_flat:   "AU_Name/Group_Name" => {...}        │
│  role_assignments_flat: "AU_Name/Role/Principal/Type" => {} │
│                                                             │
│  eligible_assignments: filtered by assignment_type          │
│  active_assignments:   filtered by assignment_type          │
│                                                             │
│  all_user_upns:        unique UPNs for data source lookups  │
│  all_role_names:       unique roles for activation          │
└─────────────────────────────────────────────────────────────┘
```

### 2. Resource Creation Order

```
┌──────────────────────────────────────────────────────────────────────────┐
│  Phase 1: Data Sources                                                   │
│  ├── data.azuread_user.users         (lookup existing users)             │
│  └── azuread_directory_role.roles    (activate required roles)           │
├──────────────────────────────────────────────────────────────────────────┤
│  Phase 2: Administrative Units                                           │
│  └── azuread_administrative_unit.this                                    │
├──────────────────────────────────────────────────────────────────────────┤
│  Phase 3: Groups (depends on AUs)                                        │
│  └── azuread_group.au_groups                                             │
├──────────────────────────────────────────────────────────────────────────┤
│  Phase 4: Members (depends on AUs, Groups, Users)                        │
│  ├── azuread_administrative_unit_member.users                            │
│  └── azuread_administrative_unit_member.groups                           │
├──────────────────────────────────────────────────────────────────────────┤
│  Phase 5: Role Assignments (depends on AUs, Roles, Users)                │
│  ├── azuread_administrative_unit_role_member.active                      │
│  └── msgraph_resource.pim_eligible                                       │
└──────────────────────────────────────────────────────────────────────────┘
```

## Resource Details

### Administrative Units (main.tf)

```hcl
resource "azuread_administrative_unit" "this" {
  for_each = { for au in var.admin_units : au.display_name => au }
  
  display_name              = each.value.display_name
  description               = try(each.value.description, null)
  hidden_membership_enabled = try(each.value.hidden_membership_enabled, false)
}
```

**Key Design Points**:
- Keyed by `display_name` for human-readable state
- Uses `try()` for optional attributes with graceful defaults

### Groups (groups.tf)

```hcl
resource "azuread_group" "au_groups" {
  for_each = local.groups_flat  # "AU_Name/Group_Name" => {...}
  
  display_name            = each.value.group_display_name
  security_enabled        = true
  administrative_unit_ids = [azuread_administrative_unit.this[each.value.au_display_name].object_id]
}
```

**Key Design Points**:
- Composite key (`AU_Name/Group_Name`) ensures uniqueness across AUs
- Groups are automatically members of their parent AU via `administrative_unit_ids`
- `security_enabled = true` for all groups (required for role assignments)

### Members (members.tf)

```hcl
resource "azuread_administrative_unit_member" "users" {
  for_each = local.user_members_flat
  
  administrative_unit_object_id = azuread_administrative_unit.this[each.value.au_display_name].object_id
  member_object_id              = data.azuread_user.users[each.value.user_principal_name].object_id
}
```

**Key Design Points**:
- Separate resources for user and group members
- Uses data source to resolve UPNs to object IDs
- Avoids conflict with `members` attribute on AU resource

### PIM Eligible Assignments (pim.tf)

```hcl
resource "msgraph_resource" "pim_eligible" {
  for_each = local.eligible_assignments
  
  url         = "roleManagement/directory/roleEligibilityScheduleRequests"
  api_version = "v1.0"
  
  body = {
    action           = "adminAssign"
    justification    = each.value.justification
    roleDefinitionId = azuread_directory_role.roles[each.value.role_display_name].template_id
    principalId      = data.azuread_user.users[each.value.principal_name].object_id
    directoryScopeId = "/administrativeUnits/${azuread_administrative_unit.this[...].object_id}"
    scheduleInfo     = { ... }
  }
}
```

**Key Design Points**:
- Uses `msgraph_resource` to call Graph API directly
- `directoryScopeId` scopes the assignment to the specific AU
- Supports both permanent (`noExpiration`) and temporary (`afterDateTime`) schedules
- Includes retry logic for throttling errors

## Validation Rules

The module enforces validation at the variable level:

### 1. Unique Display Names

```hcl
validation {
  condition = length(var.admin_units) == length(distinct([
    for au in var.admin_units : au.display_name
  ]))
  error_message = "Each admin unit must have a unique display_name."
}
```

### 2. Valid Assignment Type

```hcl
validation {
  condition = alltrue([
    for au in var.admin_units : alltrue([
      for ra in try(au.role_assignments, []) : 
        contains(["eligible", "active"], ra.assignment_type)
    ])
  ])
  error_message = "Role assignment_type must be either 'eligible' or 'active'."
}
```

### 3. Temporary Schedule End Date

```hcl
validation {
  condition = alltrue([
    for au in var.admin_units : alltrue([
      for ra in try(au.role_assignments, []) :
        try(ra.schedule.type, "permanent") == "permanent" ||
        (try(ra.schedule.type, "permanent") == "temporary" && 
         try(ra.schedule.end_date, null) != null)
    ])
  ])
  error_message = "Temporary role assignments must specify an end_date."
}
```

## Testing Strategy

The module uses **native Terraform tests** with mock providers:

```hcl
# tests/admin_units.tftest.hcl
mock_provider "azuread" {}
mock_provider "msgraph" {}

run "create_single_admin_unit" {
  command = plan
  
  variables {
    admin_units = [{ display_name = "Test AU", description = "Test" }]
  }
  
  assert {
    condition     = length(azuread_administrative_unit.this) == 1
    error_message = "Expected exactly 1 admin unit"
  }
}
```

**Test Categories**:
- Basic creation (single, multiple, empty)
- Groups within AUs
- Full configuration (AU + Groups + Members + Roles)
- Variable validation (unique names, assignment types, schedules)

**Run Tests**:
```bash
terraform test
```

## API Dependencies

### Microsoft Graph API Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/roleManagement/directory/roleEligibilityScheduleRequests` | POST | Create PIM eligible assignments |

### Required Permissions

| Permission | Purpose |
|------------|---------|
| `AdministrativeUnit.ReadWrite.All` | Create and manage AUs |
| `Directory.ReadWrite.All` | Groups, members, roles |
| `User.Read.All` | Resolve UPNs to object IDs |
| `RoleEligibilitySchedule.ReadWrite.Directory` | PIM eligible |
| `RoleManagement.ReadWrite.Directory` | Role assignments |

## Extension Points

### Adding New Attributes

1. Add optional field to `admin_units` variable type
2. Add attribute to resource using `try()` for graceful defaults
3. Add to outputs
4. Add test assertions
5. Update documentation

### Adding New Resource Types

1. Create new `.tf` file (e.g., `new_resource.tf`)
2. Add flattening logic to `locals.tf`
3. Add data sources if needed to `data.tf`
4. Add outputs to `outputs.tf`
5. Add tests to `tests/admin_units.tftest.hcl`

### Multi-Tenant Support

For multi-tenant deployments, use provider aliasing:

```hcl
provider "azuread" {
  alias     = "tenant_a"
  tenant_id = var.tenant_a_id
}

provider "azuread" {
  alias     = "tenant_b"
  tenant_id = var.tenant_b_id
}

module "admin_units_tenant_a" {
  source = "github.com/4renwald/terraform-azuread-admin-units"
  providers = {
    azuread = azuread.tenant_a
    msgraph = msgraph.tenant_a
  }
  admin_units = var.tenant_a_admin_units
}
```

## Limitations

| Limitation | Workaround |
|------------|------------|
| Renaming AU destroys/recreates | Use `moved` blocks for state surgery |
| PIM requires P2 license | Use active assignments only |
| No group membership in AUs (external groups) | Create groups within the module |
| msgraph provider maturity | Monitor provider updates |

## Future Considerations

- [ ] Support for external group references (groups not created by this module)
- [ ] Service principal role assignments
- [ ] PIM activation policies
- [ ] Conditional access policies scoped to AUs
- [ ] Import support for existing AUs
