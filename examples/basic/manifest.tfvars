# Admin Units Manifest
# This file defines all Administrative Units to be managed by Terraform.
# Add, modify, or remove entries as needed.

admin_units = [
  {
    display_name = "IT Department"
    description  = "Administrative unit for IT department users and resources"
  },
  {
    display_name = "HR Department"
    description  = "Administrative unit for HR department"
    hidden_membership_enabled = true
  },
  {
    display_name = "Finance Department"
    description  = "Administrative unit for Finance department"
  },
  {
    display_name = "Engineering"
    description  = "Administrative unit for Engineering teams"
  }
]
