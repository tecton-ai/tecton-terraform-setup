output "databricks_peering_project" {
  value = rediscloud_subscription_peering.databricks-peering.gcp_redis_project_id
}

output "databricks_peering_network_name" {
  value = rediscloud_subscription_peering.databricks-peering.gcp_redis_network_name
}

output "serving_peering_project" {
  value = rediscloud_subscription_peering.serving-peering.gcp_redis_project_id
}

output "serving_peering_network_name" {
  value = rediscloud_subscription_peering.serving-peering.gcp_redis_network_name
}
