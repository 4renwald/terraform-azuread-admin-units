# -----------------------------------------------------------------------------
# Administrative Units
# Provider: azuread for standard AUs, msgraph for restricted AUs
# -----------------------------------------------------------------------------

locals {
  # Split admin units into restricted and non-restricted
  standard_aus = {
    for au in var.admin_units : au.display_name => au
    if try(au.restricted_management_enabled, false) == false
  }
  restricted_aus = {
    for au in var.admin_units : au.display_name => au
    if try(au.restricted_management_enabled, false) == true
  }

  # Unified map of AU object IDs for use by other resources
  au_object_ids = merge(
    { for key, au in azuread_administrative_unit.this : key => au.object_id },
    { for key, au in msgraph_resource.restricted_au : key => au.output.id }
  )
}

# Create standard (non-restricted) Administrative Units via azuread provider
resource "azuread_administrative_unit" "this" {
  for_each = local.standard_aus

  display_name              = each.value.display_name
  description               = try(each.value.description, null)
  hidden_membership_enabled = try(each.value.hidden_membership_enabled, false)
}

# Create restricted Administrative Units via msgraph provider
# isMemberManagementRestricted must be set at creation time (immutable)
# Requires: Microsoft Entra ID P2 or Microsoft Entra ID Governance license
resource "msgraph_resource" "restricted_au" {
  for_each = local.restricted_aus

  url         = "directory/administrativeUnits"
  api_version = "v1.0"

  body = {
    displayName                  = each.value.display_name
    description                  = try(each.value.description, null)
    visibility                   = try(each.value.hidden_membership_enabled, false) ? "HiddenMembership" : null
    isMemberManagementRestricted = true
  }

  response_export_values = {
    id          = "id"
    displayName = "displayName"
    description = "description"
  }

  lifecycle {
    ignore_changes = [body]
  }
}
