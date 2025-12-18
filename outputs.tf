output "admin_units" {
  description = "Map of created Administrative Units with their attributes"
  value = {
    for key, au in azuread_administrative_unit.this : key => {
      id                        = au.id
      object_id                 = au.object_id
      display_name              = au.display_name
      description               = au.description
      hidden_membership_enabled = au.hidden_membership_enabled
    }
  }
}

output "admin_unit_ids" {
  description = "Map of Administrative Unit display names to their object IDs"
  value       = { for key, au in azuread_administrative_unit.this : key => au.object_id }
}
