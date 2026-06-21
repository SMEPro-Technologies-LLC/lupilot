# Cloud Storage buckets
resource "google_storage_bucket" "artifacts" {
  name          = "${var.project_id}-artifacts"
  location      = var.region
  storage_class = "STANDARD"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 90
    }
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.smepro.id
  }
}

resource "google_storage_bucket" "logs" {
  name          = "${var.project_id}-logs"
  location      = var.region
  storage_class = "NEARLINE"

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 2555  # 7 years
    }
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.smepro.id
  }
}

resource "google_storage_bucket" "ml_models" {
  name          = "${var.project_id}-ml-models"
  location      = var.region
  storage_class = "STANDARD"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 2555
    }
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.smepro.id
  }
}

resource "google_storage_bucket" "backups" {
  name          = "${var.project_id}-backups"
  location      = "US-CENTRAL1"  # Same region as primary
  storage_class = "COLDLINE"

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30
    }
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.smepro.id
  }
}

resource "google_storage_bucket" "trace_chain" {
  name          = "${var.project_id}-trace-chain"
  location      = var.region
  storage_class = "STANDARD"

  retention_policy {
    is_locked        = true
    retention_period = 0  # Permanent
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.smepro.id
  }
}

resource "google_storage_bucket" "tfstate" {
  name          = "${var.project_prefix}-tfstate"
  location      = var.region
  storage_class = "STANDARD"

  versioning {
    enabled = true
  }
}
