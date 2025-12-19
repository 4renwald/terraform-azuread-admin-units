# -----------------------------------------------------------------------------
# Administrative Unit Members
# Provider: azuread
# -----------------------------------------------------------------------------

# Add user members to Administrative Units
resource "azuread_administrative_unit_member" "users" {
  for_each = local.user_members_flat

  administrative_unit_object_id = azuread_administrative_unit.this[each.value.au_display_name].object_id
  member_object_id              = data.azuread_user.users[each.value.user_principal_name].object_id
}

# Add groups (created by this module) as members to Administrative Units
# Note: Groups created with administrative_unit_ids are automatically members,
# but this is for groups referenced in the members block that were created in groups block
resource "azuread_administrative_unit_member" "groups" {
  for_each = local.group_members_flat

  administrative_unit_object_id = azuread_administrative_unit.this[each.value.au_display_name].object_id
  member_object_id              = azuread_group.au_groups["${each.value.au_display_name}/${each.value.group_display_name}"].object_id
}
