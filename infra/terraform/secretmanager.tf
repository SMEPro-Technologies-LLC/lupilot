# Secret Manager secrets for SMEPro COS
locals {
  secrets = [
    "jwt-signing-key",
    "banner-api-credentials",
    "blackboard-api-key",
    "anthropic-api-key",
    "firecrawl-api-key",
    "sendgrid-api-key",
    "slack-webhook-url",
    "trace-chain-private-key",
    "ssl-certificate",
  ]
}

resource "google_secret_manager_secret" "smepro" {
  for_each = toset(local.secrets)
  secret_id  = "${each.value}-${var.environment}"

  replication {
    auto {}
  }
}

# KMS for CMEK
resource "google_kms_key_ring" "smepro" {
  name     = "smepro-keyring"
  location = var.region
}

resource "google_kms_crypto_key" "smepro" {
  name            = "smepro-cmekey"
  key_ring        = google_kms_key_ring.smepro.id
  rotation_period = "7776000s"  # 90 days

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "HSM"
  }
}

resource "google_kms_crypto_key_iam_member" "smepro_storage" {
  crypto_key_id = google_kms_crypto_key.smepro.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.smepro.number}@gs-project-accounts.iam.gserviceaccount.com"
}

resource "google_kms_crypto_key_iam_member" "smepro_cloudsql" {
  crypto_key_id = google_kms_crypto_key.smepro.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.smepro.number}@gcp-sa-cloud-sql.iam.gserviceaccount.com"
}

data "google_project" "smepro" {}
