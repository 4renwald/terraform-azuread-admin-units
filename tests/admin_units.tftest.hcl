# -----------------------------------------------------------------------------
# Terraform Tests for Administrative Units Module
# Uses mock providers to run tests without Azure credentials
# -----------------------------------------------------------------------------

mock_provider "azuread" {}
mock_provider "msgraph" {}

# -----------------------------------------------------------------------------
# Test: Basic Admin Unit Creation
# -----------------------------------------------------------------------------
run "create_single_admin_unit" {
  command = plan

  variables {
    admin_units = [
      {
        display_name = "Test Admin Unit"
        description  = "Test description"
      }
    ]
  }

  assert {
    condition     = length(azuread_administrative_unit.this) == 1
    error_message = "Expected exactly 1 admin unit to be created"
  }

  assert {
    condition     = azuread_administrative_unit.this["Test Admin Unit"].display_name == "Test Admin Unit"
    error_message = "Admin unit display_name doesn't match expected value"
  }

  assert {
    condition     = azuread_administrative_unit.this["Test Admin Unit"].description == "Test description"
    error_message = "Admin unit description doesn't match expected value"
  }

  assert {
    condition     = azuread_administrative_unit.this["Test Admin Unit"].hidden_membership_enabled == false
    error_message = "hidden_membership_enabled should default to false"
  }
}

run "create_multiple_admin_units" {
  command = plan

  variables {
    admin_units = [
      {
        display_name = "IT Department"
        description  = "IT admin unit"
      },
      {
        display_name              = "HR Department"
        description               = "HR admin unit"
        hidden_membership_enabled = true
      },
      {
        display_name = "Finance"
      }
    ]
  }

  assert {
    condition     = length(azuread_administrative_unit.this) == 3
    error_message = "Expected exactly 3 admin units to be created"
  }

  assert {
    condition     = azuread_administrative_unit.this["HR Department"].hidden_membership_enabled == true
    error_message = "HR Department should have hidden_membership_enabled = true"
  }

  assert {
    condition     = azuread_administrative_unit.this["Finance"].description == null
    error_message = "Finance description should be null when not provided"
  }
}

run "create_empty_list" {
  command = plan

  variables {
    admin_units = []
  }

  assert {
    condition     = length(azuread_administrative_unit.this) == 0
    error_message = "Expected no admin units when list is empty"
  }
}

# -----------------------------------------------------------------------------
# Test: Groups within Admin Units
# -----------------------------------------------------------------------------
run "create_admin_unit_with_groups" {
  command = plan

  variables {
    admin_units = [
      {
        display_name = "Test AU with Groups"
        description  = "AU for testing groups"
        groups = [
          {
            display_name = "Group A"
            description  = "First test group"
          },
          {
            display_name = "Group B"
            description  = "Second test group"
          }
        ]
      }
    ]
  }

  assert {
    condition     = length(azuread_administrative_unit.this) == 1
    error_message = "Expected exactly 1 admin unit"
  }

  assert {
    condition     = length(azuread_group.au_groups) == 2
    error_message = "Expected exactly 2 groups to be created"
  }

  assert {
    condition     = azuread_group.au_groups["Test AU with Groups/Group A"].display_name == "Group A"
    error_message = "Group A display_name doesn't match"
  }

  assert {
    condition     = azuread_group.au_groups["Test AU with Groups/Group B"].description == "Second test group"
    error_message = "Group B description doesn't match"
  }
}

# -----------------------------------------------------------------------------
# Test: Full Configuration (AU + Groups + Role Assignments)
# -----------------------------------------------------------------------------
run "create_full_configuration" {
  command = plan

  variables {
    admin_units = [
      {
        display_name = "Full Test AU"
        description  = "Complete configuration test"
        groups = [
          {
            display_name = "Admins Group"
            description  = "Admin group"
          }
        ]
        members = {
          user_principal_names = []
          group_display_names  = []
        }
        role_assignments = []
      }
    ]
  }

  assert {
    condition     = length(azuread_administrative_unit.this) == 1
    error_message = "Expected exactly 1 admin unit"
  }

  assert {
    condition     = length(azuread_group.au_groups) == 1
    error_message = "Expected exactly 1 group"
  }

  assert {
    condition     = azuread_group.au_groups["Full Test AU/Admins Group"].security_enabled == true
    error_message = "Groups should have security_enabled = true"
  }
}

# -----------------------------------------------------------------------------
# Test: Variable Validation - Unique display_name
# -----------------------------------------------------------------------------
run "validation_unique_display_names" {
  command         = plan
  expect_failures = [var.admin_units]

  variables {
    admin_units = [
      {
        display_name = "Duplicate Name"
      },
      {
        display_name = "Duplicate Name"
      }
    ]
  }
}

# -----------------------------------------------------------------------------
# Test: Variable Validation - Assignment Type
# -----------------------------------------------------------------------------
run "validation_assignment_type" {
  command         = plan
  expect_failures = [var.admin_units]

  variables {
    admin_units = [
      {
        display_name = "Test AU"
        role_assignments = [
          {
            role_display_name = "User Administrator"
            assignment_type   = "invalid_type"
            principal_names   = ["user@example.com"]
          }
        ]
      }
    ]
  }
}

# -----------------------------------------------------------------------------
# Test: Variable Validation - Temporary Schedule requires end_date
# -----------------------------------------------------------------------------
run "validation_temporary_schedule_end_date" {
  command         = plan
  expect_failures = [var.admin_units]

  variables {
    admin_units = [
      {
        display_name = "Test AU"
        role_assignments = [
          {
            role_display_name = "User Administrator"
            assignment_type   = "eligible"
            principal_names   = ["user@example.com"]
            schedule = {
              type = "temporary"
              # Missing end_date should fail validation
            }
          }
        ]
      }
    ]
  }
}

