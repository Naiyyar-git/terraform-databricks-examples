subscription_id = "64d53302-043c-437a-8d30-96458eef0261"
account_id      = ""

location                        = "westus2"
existing_resource_group_name    = "db_lh_example_rg"
project_name                    = "db_lh_example"
environment_name                = "db_lh_example_env"
databricks_workspace_name       = "db_lh_example_ws"
spoke_vnet_address_space        = "10.178.0.0/16"
private_subnet_address_prefixes = ["10.178.0.0/20"]
public_subnet_address_prefixes  = ["10.178.16.0/20"]
shared_resource_group_name      = "db_lh_example_shared_rg"
metastore_name                  = "db_lh_metastore"
metastore_storage_name          = "dblhmetanaiyyar"
access_connector_name           = "db_lh_example_connector"
landing_external_location_name  = "dblhlandingnaiyyar"
landing_adls_path               = "abfss://example@dblhlandingnaiyyar.dfs.core.windows.net"
landing_adls_rg                 = "dblhexamplelanding"
metastore_admins                = ["naiyyar@outlook.com"]

tags = {
  Owner = "naiyyar@outlook.com"
}