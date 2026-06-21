resource "google_sql_database_instance" "smepro" {
  name             = "smepro-cos-postgres-${var.environment}"
  database_version = var.db_version
  region           = var.region

  settings {
    tier              = var.db_tier
    availability_type = var.environment == "production" ? "REGIONAL" : "ZONAL"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.smepro.id
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = 30
      }
    }

    maintenance_window {
      day          = 7
      hour         = 4
      update_track = "stable"
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }

    database_flags {
      name  = "max_connections"
      value = "500"
    }

    database_flags {
      name  = "log_min_duration_statement"
      value = "1000"
    }
  }

  deletion_protection = var.environment == "production" ? true : false

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

resource "google_sql_database" "smepro" {
  name     = "smepro"
  instance = google_sql_database_instance.smepro.name
}

resource "google_sql_user" "smepro" {
  name     = "smepro"
  instance = google_sql_database_instance.smepro.name
  password = random_password.db_password.result
}

resource "random_password" "db_password" {
  length  = 32
  special = true
}

resource "google_secret_manager_secret" "db_password" {
  secret_id = "db-password-${var.environment}"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.smepro.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.smepro_private_ip_alloc.name]
}

resource "google_compute_global_address" "smepro_private_ip_alloc" {
  name          = "smepro-private-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.smepro.id
}
