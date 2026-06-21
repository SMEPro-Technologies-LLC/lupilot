resource "google_redis_instance" "smepro" {
  name               = "smepro-cos-redis-${var.environment}"
  tier               = "STANDARD_HA"
  memory_size_gb     = var.environment == "production" ? 8 : 2
  region             = var.region
  redis_version      = "REDIS_7_0"
  authorized_network = google_compute_network.smepro.id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  maintenance_policy {
    weekly_maintenance_window {
      day = "TUESDAY"
      start_time {
        hours   = 3
        minutes = 0
      }
    }
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}
