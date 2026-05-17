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
  workspace_access           = true
  databricks_sql_access      = true
  allow_cluster_create       = true # POC: notebook/cluster smoke tests
  allow_instance_pool_create = false
}

# Create SQL warehouse + Admin UI require workspace admin (built-in admins group).
data "databricks_group" "admins" {
  provider     = databricks.workspace
  display_name = "admins"
}

resource "databricks_group_member" "workspace_admin" {
  provider  = databricks.workspace
  for_each  = toset(local.workspace_ui_users)
  group_id  = data.databricks_group.admins.id
  member_id = databricks_user.workspace_ui_access[each.key].id
}
