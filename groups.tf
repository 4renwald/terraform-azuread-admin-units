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
  administrative_unit_ids = [local.au_object_ids[each.value.au_display_name]]

  lifecycle {
    # Prevent Terraform from trying to remove AU membership managed by this resource
    ignore_changes = [administrative_unit_ids]
  }
}
