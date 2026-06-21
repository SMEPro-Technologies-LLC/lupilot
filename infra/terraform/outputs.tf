output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "region" {
  description = "GCP Region"
  value       = var.region
}

output "gke_cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.smepro.name
}

output "gke_cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.smepro.endpoint
  sensitive   = true
}

output "cloudsql_instance_name" {
  description = "Cloud SQL instance name"
  value       = google_sql_database_instance.smepro.name
}

output "cloudsql_instance_connection_name" {
  description = "Cloud SQL instance connection name"
  value       = google_sql_database_instance.smepro.connection_name
}

output "cloudsql_private_ip" {
  description = "Cloud SQL private IP"
  value       = google_sql_database_instance.smepro.private_ip_address
}

output "redis_host" {
  description = "Memorystore Redis host"
  value       = google_redis_instance.smepro.host
}

output "redis_port" {
  description = "Memorystore Redis port"
  value       = google_redis_instance.smepro.port
}

output "artifact_registry_url" {
  description = "Artifact Registry URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/artifact-registry/smepro"
}

output "load_balancer_ip" {
  description = "Load balancer IP address"
  value       = google_compute_global_address.smepro.address
}
