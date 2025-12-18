variable "admin_units" {
  description = "List of Administrative Units to create"
  type = list(object({
    display_name              = string
    description               = optional(string)
    hidden_membership_enabled = optional(bool, false)
  }))
  default = []
}
