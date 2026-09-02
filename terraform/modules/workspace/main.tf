resource "fabric_workspace" "this" {
  display_name                   = var.display_name
  description                    = var.description
  capacity_id                    = var.capacity_id
  skip_capacity_state_validation = true

  identity = {
    type = "SystemAssigned"
  }
}

resource "fabric_workspace_role_assignment" "this" {
  for_each = var.role_assignments

  workspace_id = fabric_workspace.this.id
  principal = {
    id   = each.value.principal_id
    type = each.value.principal_type
  }
  role = each.value.role
}
