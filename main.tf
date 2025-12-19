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
