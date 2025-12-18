output "admin_units" {
  description = "Map of created Administrative Units"
  value       = module.admin_units.admin_units
}

output "admin_unit_ids" {
  description = "Map of Administrative Unit display names to their object IDs"
  value       = module.admin_units.admin_unit_ids
}
