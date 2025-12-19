# -----------------------------------------------------------------------------
# Locals for flattening nested structures
# -----------------------------------------------------------------------------

locals {
  # Flatten groups across all admin units
  # Key: "AU_Name/Group_Name"
  groups_flat = merge([
    for au in var.admin_units : {
      for group in try(au.groups, []) :
      "${au.display_name}/${group.display_name}" => {
        au_display_name    = au.display_name
        group_display_name = group.display_name
        description        = try(group.description, null)
      }
    }
  ]...)

  # Flatten user members across all admin units
  # Key: "AU_Name/user@domain.com"
  user_members_flat = merge([
    for au in var.admin_units : {
      for upn in try(au.members.user_principal_names, []) :
      "${au.display_name}/${upn}" => {
        au_display_name     = au.display_name
        user_principal_name = upn
      }
    }
  ]...)

  # Flatten group members across all admin units (references to groups created above)
  # Key: "AU_Name/Group_Name"
  group_members_flat = merge([
    for au in var.admin_units : {
      for group_name in try(au.members.group_display_names, []) :
      "${au.display_name}/${group_name}" => {
        au_display_name    = au.display_name
        group_display_name = group_name
      }
    }
  ]...)

  # Flatten role assignments with principals
  # Key: "AU_Name/Role_Name/principal@domain.com/assignment_type"
  role_assignments_flat = merge([
    for au in var.admin_units : merge([
      for ra in try(au.role_assignments, []) : {
        for principal in ra.principal_names :
        "${au.display_name}/${ra.role_display_name}/${principal}/${ra.assignment_type}" => {
          au_display_name   = au.display_name
          role_display_name = ra.role_display_name
          assignment_type   = ra.assignment_type
          principal_name    = principal
          schedule_type     = try(ra.schedule.type, "permanent")
          start_date        = try(ra.schedule.start_date, null)
          end_date          = try(ra.schedule.end_date, null)
          justification     = try(ra.justification, "Managed by Terraform")
        }
      }
    ]...)
  ]...)

  # Separate eligible and active role assignments
  eligible_assignments = {
    for k, v in local.role_assignments_flat : k => v
    if v.assignment_type == "eligible"
  }

  active_assignments = {
    for k, v in local.role_assignments_flat : k => v
    if v.assignment_type == "active"
  }

  # Collect unique UPNs for data source lookups
  all_user_upns = distinct(concat(
    [for k, v in local.user_members_flat : v.user_principal_name],
    [for k, v in local.role_assignments_flat : v.principal_name]
  ))

  # Collect unique role display names for data source lookups
  all_role_names = distinct([
    for k, v in local.role_assignments_flat : v.role_display_name
  ])

  # Current timestamp for schedule start (if not specified)
  current_timestamp = timestamp()
}
