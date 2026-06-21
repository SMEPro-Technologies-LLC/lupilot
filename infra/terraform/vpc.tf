resource "google_compute_network" "smepro" {
  name                    = "${var.project_prefix}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "smepro" {
  name          = "${var.project_prefix}-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.smepro.id

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/16"
  }

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_router" "smepro" {
  name    = "${var.project_prefix}-router"
  region  = var.region
  network = google_compute_network.smepro.id
}

resource "google_compute_router_nat" "smepro" {
  name                               = "${var.project_prefix}-nat"
  router                             = google_compute_router.smepro.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_global_address" "smepro" {
  name = "${var.project_prefix}-lb-ip"
}

resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_prefix}-allow-internal"
  network = google_compute_network.smepro.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/16", "10.1.0.0/16", "10.2.0.0/16"]
}

resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.project_prefix}-allow-health-checks"
  network = google_compute_network.smepro.name

  allow {
    protocol = "tcp"
    ports    = ["8080", "3000", "80", "443"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["gke-${var.gke_cluster_name}"]
}
