# -----------------------------------------------------------------------------
# PIM Role Assignments (Eligible and Active)
# Provider: msgraph (for eligible), azuread (for active)
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Active Role Assignments (using azuread provider)
# These are permanent/immediate role assignments scoped to the Administrative Unit
# -----------------------------------------------------------------------------
resource "azuread_administrative_unit_role_member" "active" {
  for_each = local.active_assignments

  administrative_unit_object_id = local.au_object_ids[each.value.au_display_name]
  role_object_id                = azuread_directory_role.roles[each.value.role_display_name].object_id
  member_object_id              = data.azuread_user.users[each.value.principal_name].object_id
}

# -----------------------------------------------------------------------------
# PIM Eligible Role Assignments (using msgraph provider)
# These create role eligibility schedule requests via Microsoft Graph API
# Requires: Microsoft Entra ID P2 or Microsoft Entra ID Governance license
# -----------------------------------------------------------------------------
resource "msgraph_resource" "pim_eligible" {
  for_each = local.eligible_assignments

  url         = "roleManagement/directory/roleEligibilityScheduleRequests"
  api_version = "v1.0"

  body = {
    action           = "adminAssign"
    justification    = each.value.justification
    roleDefinitionId = azuread_directory_role.roles[each.value.role_display_name].template_id
    principalId      = data.azuread_user.users[each.value.principal_name].object_id
    directoryScopeId = "/administrativeUnits/${local.au_object_ids[each.value.au_display_name]}"
    scheduleInfo = {
      startDateTime = coalesce(each.value.start_date, formatdate("YYYY-MM-DD'T'hh:mm:ss'Z'", local.current_timestamp))
      expiration = each.value.schedule_type == "permanent" ? {
        type = "noExpiration"
        } : {
        type        = "afterDateTime"
        endDateTime = each.value.end_date
      }
    }
  }

  response_export_values = {
    id               = "id"
    status           = "status"
    principalId      = "principalId"
    roleDefinitionId = "roleDefinitionId"
    directoryScopeId = "directoryScopeId"
  }

  # Retry on throttling errors
  retry = {
    error_message_regex = [
      ".*429.*",
      ".*throttled.*",
      ".*rate limit.*",
      ".*Too Many Requests.*"
    ]
  }

  timeouts {
    create = "10m"
  }

  lifecycle {
    # The schedule request ID changes on each request, so we ignore it
    ignore_changes = [body]
  }
}

