# -----------------------------------------------------------------------------
# Administrative Units
# Provider: azuread
# -----------------------------------------------------------------------------

# Create Administrative Units from the provided list
resource "azuread_administrative_unit" "this" {
  for_each = { for au in var.admin_units : au.display_name => au }

  display_name              = each.value.display_name
  description               = try(each.value.description, null)
  hidden_membership_enabled = try(each.value.hidden_membership_enabled, false)
}

# -----------------------------------------------------------------------------
# Restricted Administrative Units
# Provider: msgraph (azuread provider doesn't support isMemberManagementRestricted)
# Requires: Microsoft Entra ID P2 or Microsoft Entra ID Governance license
# -----------------------------------------------------------------------------
locals {
  restricted_aus = {
    for au in var.admin_units : au.display_name => au
    if try(au.restricted_management_enabled, false) == true
  }
}

# Patch AUs to enable restricted management via Microsoft Graph API
# Note: Uses URL pointing directly to the AU to perform PATCH operations
resource "msgraph_resource" "restricted_au" {
  for_each = local.restricted_aus

  url         = "directory/administrativeUnits/${azuread_administrative_unit.this[each.key].object_id}"
  api_version = "v1.0"

  body = {
    isMemberManagementRestricted = true
  }

  response_export_values = {
    id                           = "id"
    displayName                  = "displayName"
    isMemberManagementRestricted = "isMemberManagementRestricted"
  }
}
