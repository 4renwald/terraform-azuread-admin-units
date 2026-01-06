# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

# Administrative Units
output "admin_units" {
  description = "Map of created Administrative Units with their attributes"
  value = {
    for key, au in azuread_administrative_unit.this : key => {
      id                            = au.id
      object_id                     = au.object_id
      display_name                  = au.display_name
      description                   = au.description
      hidden_membership_enabled     = au.hidden_membership_enabled
      restricted_management_enabled = contains(keys(terraform_data.restricted_au), key)
    }
  }
}

output "admin_unit_ids" {
  description = "Map of Administrative Unit display names to their object IDs"
  value       = { for key, au in azuread_administrative_unit.this : key => au.object_id }
}

# Groups
output "groups" {
  description = "Map of created groups within Administrative Units"
  value = {
    for key, group in azuread_group.au_groups : key => {
      id           = group.id
      object_id    = group.object_id
      display_name = group.display_name
      description  = group.description
    }
  }
}

output "group_ids" {
  description = "Map of group keys to their object IDs"
  value       = { for key, group in azuread_group.au_groups : key => group.object_id }
}

# Members
output "user_members" {
  description = "Map of user members added to Administrative Units"
  value = {
    for key, member in azuread_administrative_unit_member.users : key => {
      administrative_unit_object_id = member.administrative_unit_object_id
      member_object_id              = member.member_object_id
    }
  }
}

output "group_members" {
  description = "Map of group members added to Administrative Units"
  value = {
    for key, member in azuread_administrative_unit_member.groups : key => {
      administrative_unit_object_id = member.administrative_unit_object_id
      member_object_id              = member.member_object_id
    }
  }
}

# Role Assignments
output "active_role_assignments" {
  description = "Map of active role assignments scoped to Administrative Units"
  value = {
    for key, assignment in azuread_administrative_unit_role_member.active : key => {
      administrative_unit_object_id = assignment.administrative_unit_object_id
      role_object_id                = assignment.role_object_id
      member_object_id              = assignment.member_object_id
    }
  }
}

output "eligible_role_assignments" {
  description = "Map of PIM eligible role assignments scoped to Administrative Units"
  value = {
    for key, assignment in msgraph_resource.pim_eligible : key => {
      id                 = try(assignment.output.id, null)
      status             = try(assignment.output.status, null)
      principal_id       = try(assignment.output.principalId, null)
      role_definition_id = try(assignment.output.roleDefinitionId, null)
      directory_scope_id = try(assignment.output.directoryScopeId, null)
    }
  }
}

# Summary
output "summary" {
  description = "Summary of all created resources"
  value = {
    admin_units_count               = length(azuread_administrative_unit.this)
    groups_count                    = length(azuread_group.au_groups)
    user_members_count              = length(azuread_administrative_unit_member.users)
    group_members_count             = length(azuread_administrative_unit_member.groups)
    active_role_assignments_count   = length(azuread_administrative_unit_role_member.active)
    eligible_role_assignments_count = length(msgraph_resource.pim_eligible)
  }
}

