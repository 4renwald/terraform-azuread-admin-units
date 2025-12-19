# Admin Units Manifest
# This file defines all Administrative Units to be managed by Terraform.
# Add, modify, or remove entries as needed.

admin_units = [
  {
    display_name = "IT Department"
    description  = "Administrative unit for IT department users and resources"

    groups = [
      {
        display_name = "GRP_IT_Admins"
        description  = "IT Administrators group"
      },
      {
        display_name = "GRP_IT_Support"
        description  = "IT Support staff group"
      }
    ]

    members = {
      user_principal_names = []
      group_display_names  = []
    }

    role_assignments = [
      {
        role_display_name = "User Administrator"
        assignment_type   = "eligible"
        principal_names   = ["it_admin@contoso.onmicrosoft.com"]
        schedule = {
          type = "permanent"
        }
        justification = "IT Admin needs User Administrator role for IT department"
      }
    ]
  },
  {
    display_name              = "HR Department"
    description               = "Administrative unit for HR department"
    hidden_membership_enabled = true

    groups = [
      {
        display_name = "GRP_HR_Admins"
        description  = "HR Administrators group"
      }
    ]

    members = {
      user_principal_names = [
        "hr_user1@contoso.onmicrosoft.com",
        "hr_user2@contoso.onmicrosoft.com"
      ]
      group_display_names = []
    }

    role_assignments = [
      {
        role_display_name = "User Administrator"
        assignment_type   = "active"
        principal_names   = ["hr_admin@contoso.onmicrosoft.com"]
        justification     = "HR Admin permanent access"
      }
    ]
  },
  {
    display_name = "Finance Department"
    description  = "Administrative unit for Finance department"
    groups       = []
    members = {
      user_principal_names = []
      group_display_names  = []
    }
    role_assignments = []
  },
  {
    display_name = "Engineering"
    description  = "Administrative unit for Engineering teams"

    groups = [
      {
        display_name = "GRP_ENG_DevOps"
        description  = "DevOps engineers group"
      },
      {
        display_name = "GRP_ENG_Platform"
        description  = "Platform engineers group"
      }
    ]

    members = {
      user_principal_names = []
      group_display_names  = ["GRP_ENG_DevOps", "GRP_ENG_Platform"]
    }

    role_assignments = [
      {
        role_display_name = "User Administrator"
        assignment_type   = "eligible"
        principal_names   = ["eng_lead@contoso.onmicrosoft.com"]
        schedule = {
          type       = "temporary"
          start_date = "2025-01-01T00:00:00Z"
          end_date   = "2025-12-31T23:59:59Z"
        }
        justification = "Engineering lead temporary eligible access for 2025"
      }
    ]
  }
]

