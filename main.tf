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
# Provider: terraform_data + az CLI (azuread provider doesn't support isMemberManagementRestricted)
# Requires: Microsoft Entra ID P2 or Microsoft Entra ID Governance license
# -----------------------------------------------------------------------------
locals {
  restricted_aus = {
    for au in var.admin_units : au.display_name => au
    if try(au.restricted_management_enabled, false) == true
  }
}

# Patch AUs to enable restricted management via Microsoft Graph API
resource "terraform_data" "restricted_au" {
  for_each = local.restricted_aus

  triggers_replace = {
    au_id      = azuread_administrative_unit.this[each.key].object_id
    restricted = true
  }

  provisioner "local-exec" {
    command = <<-EOT
      az rest --method PATCH \
        --url "https://graph.microsoft.com/v1.0/directory/administrativeUnits/${azuread_administrative_unit.this[each.key].object_id}" \
        --headers "Content-Type=application/json" \
        --body '{"isMemberManagementRestricted": true}'
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      az rest --method PATCH \
        --url "https://graph.microsoft.com/v1.0/directory/administrativeUnits/${self.triggers_replace.au_id}" \
        --headers "Content-Type=application/json" \
        --body '{"isMemberManagementRestricted": false}' || true
    EOT
  }
}
