variable "admin_units" {
  description = "List of Administrative Units to create"
  type = list(object({
    display_name              = string
    description               = optional(string)
    hidden_membership_enabled = optional(bool, false)
  }))
  default = []

  validation {
    condition     = length(var.admin_units) == length(distinct([for au in var.admin_units : au.display_name]))
    error_message = "Each admin unit must have a unique display_name."
  }
}
