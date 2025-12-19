# -----------------------------------------------------------------------------
# Data sources for looking up existing users and roles
# -----------------------------------------------------------------------------

# Lookup users by UPN for member and role assignments
data "azuread_user" "users" {
  for_each = toset(local.all_user_upns)

  user_principal_name = each.value
}

# Enable directory roles that are needed (directory roles must be activated before use)
# Note: azuread_directory_role activates the role if not already activated
resource "azuread_directory_role" "roles" {
  for_each = toset(local.all_role_names)

  display_name = each.value
}

