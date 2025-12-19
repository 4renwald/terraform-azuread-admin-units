output "admin_units" {
  description = "Map of created Administrative Units"
  value       = module.admin_units.admin_units
}

output "admin_unit_ids" {
  description = "Map of Administrative Unit display names to their object IDs"
  value       = module.admin_units.admin_unit_ids
}

output "groups" {
  description = "Map of created groups within Administrative Units"
  value       = module.admin_units.groups
}

output "user_members" {
  description = "Map of user members added to Administrative Units"
  value       = module.admin_units.user_members
}

output "group_members" {
  description = "Map of group members added to Administrative Units"
  value       = module.admin_units.group_members
}

output "active_role_assignments" {
  description = "Map of active role assignments"
  value       = module.admin_units.active_role_assignments
}

output "eligible_role_assignments" {
  description = "Map of PIM eligible role assignments"
  value       = module.admin_units.eligible_role_assignments
}

output "summary" {
  description = "Summary of all created resources"
  value       = module.admin_units.summary
}
