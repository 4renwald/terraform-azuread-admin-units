variable "admin_units" {
  description = "List of Administrative Units to create with groups, members, and role assignments"
  type = list(object({
    display_name              = string
    description               = optional(string)
    hidden_membership_enabled = optional(bool, false)

    # Groups to create within this Administrative Unit
    groups = optional(list(object({
      display_name = string
      description  = optional(string)
    })), [])

    # Members to add to this Administrative Unit
    members = optional(object({
      user_principal_names = optional(list(string), [])
      group_display_names  = optional(list(string), []) # References groups created above
    }), {})

    # Scoped role assignments for this Administrative Unit
    role_assignments = optional(list(object({
      role_display_name = string
      assignment_type   = string       # "eligible" or "active"
      principal_names   = list(string) # UPNs for users
      schedule = optional(object({
        type       = optional(string, "permanent") # "permanent" or "temporary"
        start_date = optional(string)              # ISO 8601 format
        end_date   = optional(string)              # ISO 8601 format, required if type is "temporary"
      }), { type = "permanent" })
      justification = optional(string, "Managed by Terraform")
    })), [])
  }))
  default = []

  validation {
    condition     = length(var.admin_units) == length(distinct([for au in var.admin_units : au.display_name]))
    error_message = "Each admin unit must have a unique display_name."
  }

  validation {
    condition = alltrue([
      for au in var.admin_units : alltrue([
        for ra in try(au.role_assignments, []) : contains(["eligible", "active"], ra.assignment_type)
      ])
    ])
    error_message = "Role assignment_type must be either 'eligible' or 'active'."
  }

  validation {
    condition = alltrue([
      for au in var.admin_units : alltrue([
        for ra in try(au.role_assignments, []) :
        try(ra.schedule.type, "permanent") == "permanent" ||
        (try(ra.schedule.type, "permanent") == "temporary" && try(ra.schedule.end_date, null) != null)
      ])
    ])
    error_message = "Temporary role assignments must specify an end_date."
  }
}
