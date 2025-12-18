# Basic Example

This example demonstrates how to use the terraform-azuread-admin-units module with a manifest file.

## Usage

1. Review and modify `manifest.tfvars` to define your Administrative Units
2. Initialize Terraform:

```bash
terraform init
```

3. Plan the changes:

```bash
terraform plan -var-file="manifest.tfvars"
```

4. Apply the changes:

```bash
terraform apply -var-file="manifest.tfvars"
```

## Authentication

The Azure AD provider can be authenticated using:

- **Azure CLI**: Run `az login` before running Terraform
- **Service Principal**: Set environment variables:
  - `ARM_TENANT_ID`
  - `ARM_CLIENT_ID`
  - `ARM_CLIENT_SECRET`

## Manifest File

The `manifest.tfvars` file contains the list of Administrative Units to manage. Each entry can have:

- `display_name` (required): The name of the Administrative Unit
- `description` (optional): A description for the Administrative Unit
- `hidden_membership_enabled` (optional): Whether membership is hidden (default: false)
