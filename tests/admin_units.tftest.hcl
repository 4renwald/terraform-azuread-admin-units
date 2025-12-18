# Mock provider to run tests without Azure credentials
mock_provider "azuread" {}

# Test: Validate admin units are created correctly
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
        display_name = "HR Department"
        description  = "HR admin unit"
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
