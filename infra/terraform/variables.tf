variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "db_tier" {
  description = "Cloud SQL tier"
  type        = string
  default     = "db-custom-8-32768"
}

variable "db_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "POSTGRES_16"
}

variable "gke_cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "smepro-cos-gke"
}

variable "domain" {
  description = "Domain for ingress"
  type        = string
  default     = "smepro-cos.lamar.edu"
}
