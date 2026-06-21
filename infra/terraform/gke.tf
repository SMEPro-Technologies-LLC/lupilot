# GKE Autopilot Cluster
resource "google_container_cluster" "smepro" {
  name     = var.gke_cluster_name
  location = var.region

  enable_autopilot = true

  network    = google_compute_network.smepro.id
  subnetwork = google_compute_subnetwork.smepro.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.0.0.0/8"
      display_name = "lamar-campus"
    }
    cidr_blocks {
      cidr_block   = "35.235.240.0/20"
      display_name = "cloud-build"
    }
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  release_channel {
    channel = "REGULAR"
  }

  depends_on = [google_project_service.apis]
}

# Service accounts for Workload Identity
resource "google_service_account" "api_gateway" {
  account_id   = "sa-api-gateway"
  display_name = "API Gateway Service Account"
}

resource "google_service_account" "connectors" {
  account_id   = "sa-connectors"
  display_name = "Connector Workers Service Account"
}

resource "google_service_account" "ml_jobs" {
  account_id   = "sa-ml-jobs"
  display_name = "ML Jobs Service Account"
}

resource "google_service_account" "cloudsql" {
  account_id   = "sa-cloudsql"
  display_name = "Cloud SQL Proxy Service Account"
}

resource "google_service_account" "monitoring" {
  account_id   = "sa-monitoring"
  display_name = "Monitoring Service Account"
}

# IAM bindings for Workload Identity
resource "google_project_iam_member" "api_gateway" {
  for_each = toset([
    "roles/cloudsql.client",
    "roles/secretmanager.secretAccessor",
    "roles/pubsub.publisher",
  ])
  role   = each.value
  member = "serviceAccount:${google_service_account.api_gateway.email}"
}

resource "google_project_iam_member" "connectors" {
  for_each = toset([
    "roles/storage.objectAdmin",
    "roles/pubsub.publisher",
    "roles/secretmanager.secretAccessor",
  ])
  role   = each.value
  member = "serviceAccount:${google_service_account.connectors.email}"
}

resource "google_project_iam_member" "ml_jobs" {
  for_each = toset([
    "roles/storage.objectAdmin",
    "roles/pubsub.subscriber",
    "roles/aiplatform.user",
  ])
  role   = each.value
  member = "serviceAccount:${google_service_account.ml_jobs.email}"
}

resource "google_project_iam_member" "cloudsql" {
  role   = "roles/cloudsql.client"
  member = "serviceAccount:${google_service_account.cloudsql.email}"
}

resource "google_project_iam_member" "monitoring" {
  for_each = toset([
    "roles/monitoring.metricWriter",
    "roles/logging.logWriter",
  ])
  role   = each.value
  member = "serviceAccount:${google_service_account.monitoring.email}"
}

# Workload Identity bindings
resource "google_service_account_iam_member" "api_gateway_wi" {
  service_account_id = google_service_account.api_gateway.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[api-gateway/k8s-api-gateway]"
}

resource "google_service_account_iam_member" "connectors_wi" {
  service_account_id = google_service_account.connectors.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[connector-ingestion/k8s-connector-workers]"
}

resource "google_service_account_iam_member" "ml_jobs_wi" {
  service_account_id = google_service_account.ml_jobs.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[ml-jobs/k8s-ml-jobs]"
}

resource "google_service_account_iam_member" "cloudsql_wi" {
  service_account_id = google_service_account.cloudsql.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[trust-model/k8s-cloudsql-proxy]"
}

resource "google_service_account_iam_member" "monitoring_wi" {
  service_account_id = google_service_account.monitoring.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[monitoring/k8s-monitoring]"
}
