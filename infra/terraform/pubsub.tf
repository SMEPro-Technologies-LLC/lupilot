# Pub/Sub topics for SMEPro COS
locals {
  topics = [
    "banner-changes",
    "blackboard-events",
    "regulatory-changes",
    "transcript-submissions",
    "accreditation-evidence",
    "ml-job-queue",
    "approval-events",
    "notification-events",
    "evidence-chain",
    "compliance-alerts",
    "bias-audit-triggers",
    "model-lifecycle",
  ]
}

resource "google_pubsub_topic" "smepro" {
  for_each = toset(local.topics)
  name     = each.value

  message_retention_duration = each.value == "regulatory-changes" || each.value == "compliance-alerts" ? "2592000s" : "604800s"

  labels = {
    environment = var.environment
    project     = var.project_prefix
  }
}

resource "google_pubsub_subscription" "smepro" {
  for_each = toset(local.topics)
  name     = "${each.value}-sub"
  topic    = google_pubsub_topic.smepro[each.value].id

  ack_deadline_seconds = 60

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.smepro["ml-job-queue"].id
    max_delivery_attempts = 5
  }
}
