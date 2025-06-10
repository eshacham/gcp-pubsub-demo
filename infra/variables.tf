variable "gcp_project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "gcp_region" {
  description = "The GCP region for resources like Cloud Functions and regional buckets."
  type        = string
  default     = "us-central1"
}

variable "source_bucket_name_suffix" {
  description = "Suffix for the source GCS bucket name. Full name will be <project_id>-<suffix>-<random_hex>."
  type        = string
  default     = "source-files"
}

variable "target_bucket_name_suffix" {
  description = "Suffix for the target GCS bucket name. Full name will be <project_id>-<suffix>-<random_hex>."
  type        = string
  default     = "processed-files"
}

variable "pubsub_topic_id" {
  description = "The ID for the Pub/Sub topic (e.g., 'gcs-file-events')."
  type        = string
  default     = "gcs-file-events"
}

variable "pubsub_subscription_id" {
  description = "The ID for the Pub/Sub subscription (e.g., 'gcs-file-event-subscriber')."
  type        = string
  default     = "gcs-file-event-subscriber"
}

variable "cloud_function_name" {
  description = "Name for the Cloud Function."
  type        = string
  default     = "gcs-to-pubsub-publisher"
}

variable "function_source_dir" {
  description = "Path to the directory containing Cloud Function source code (relative to this Terraform module)."
  type        = string
  default     = "function_source/"
}

variable "cloud_run_job_name" {
  description = "Name for the Cloud Run Job that runs the subscriber."
  type        = string
  default     = "pubsub-gcs-subscriber-job"
}

variable "subscriber_docker_image" {
  description = "The full path to the Docker image for the subscriber (e.g., gcr.io/PROJECT_ID/IMAGE_NAME:TAG)."
  type        = string
  # No default, this should be explicitly set or built by a CI/CD pipeline.
}