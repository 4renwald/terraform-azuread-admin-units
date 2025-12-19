# -----------------------------------------------------------------------------
# Groups within Administrative Units
# Provider: azuread
# -----------------------------------------------------------------------------

# Create security groups within each Administrative Unit
resource "azuread_group" "au_groups" {
  for_each = local.groups_flat

  display_name            = each.value.group_display_name
  description             = each.value.description
  security_enabled        = true
  administrative_unit_ids = [azuread_administrative_unit.this[each.value.au_display_name].object_id]

  lifecycle {
    # Prevent Terraform from trying to remove AU membership managed by this resource
    ignore_changes = [administrative_unit_ids]
  }
}
