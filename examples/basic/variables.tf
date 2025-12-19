variable "admin_units" {
  description = "List of Administrative Units to create with groups, members, and role assignments"
  type = list(object({
    display_name              = string
    description               = optional(string)
    hidden_membership_enabled = optional(bool, false)

    groups = optional(list(object({
      display_name = string
      description  = optional(string)
    })), [])

    members = optional(object({
      user_principal_names = optional(list(string), [])
      group_display_names  = optional(list(string), [])
    }), {})

    role_assignments = optional(list(object({
      role_display_name = string
      assignment_type   = string
      principal_names   = list(string)
      schedule = optional(object({
        type       = optional(string, "permanent")
        start_date = optional(string)
        end_date   = optional(string)
      }), { type = "permanent" })
      justification = optional(string, "Managed by Terraform")
    })), [])
  }))
  default = []
}
