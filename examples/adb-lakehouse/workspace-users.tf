# Databricks UI auth is separate from Azure RBAC. The workspace was created by a
# service principal (Jenkins); your login must still get workspace entitlements.
# These resources run as that same SP against the Workspace API (SCIM).

locals {
  workspace_ui_users = length(var.workspace_user_emails) > 0 ? var.workspace_user_emails : var.metastore_admins
}

resource "databricks_user" "workspace_ui_access" {
  provider   = databricks.workspace
  for_each   = toset(local.workspace_ui_users)
  user_name  = each.value
  # Required to use notebooks / workspace UI (see Databricks entitlement docs).
  workspace_access      = true
  databricks_sql_access = true
}
