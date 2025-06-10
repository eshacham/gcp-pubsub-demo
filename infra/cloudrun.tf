locals {
  # Sanitize and truncate the job name for use in the service account ID
  # Max length for SA ID is 30. Prefix "crj-" is 4 chars, suffix "-sa" is 3 chars.
  # So, the job name part can be at most 30 - 4 - 3 = 23 chars.
  sanitized_cr_job_name_for_sa = replace(var.cloud_run_job_name, "_", "-")
  truncated_cr_job_name_for_sa = substr(local.sanitized_cr_job_name_for_sa, 0, 23)
  cr_job_sa_account_id         = "crj-${local.truncated_cr_job_name_for_sa}-sa"
}

resource "google_service_account" "cr_job_sa" {
  account_id   = local.cr_job_sa_account_id
  display_name = "SA for Cloud Run Job ${var.cloud_run_job_name}"
  project      = var.gcp_project_id
}

resource "google_cloud_run_v2_job" "subscriber_job" {
  name     = var.cloud_run_job_name
  location = var.gcp_region
  project  = var.gcp_project_id

  template {
    task_count = 1 # Number of tasks to run in parallel for this execution
    template {
      service_account = google_service_account.cr_job_sa.email
      max_retries     = 3 # How many times to retry a failed task
      timeout         = "600s" # Max execution time for a task (e.g., 10 minutes)

      containers {
        image = var.subscriber_docker_image
        # resources { # Optional: Define CPU and memory limits/requests
        #   limits = {
        #     cpu    = "1"
        #     memory = "512Mi"
        #   }
        # }
        env {
          name  = "GCP_PROJECT_ID"
          value = var.gcp_project_id
        }
        env {
          name  = "PUBSUB_SUBSCRIPTION_ID"
          value = google_pubsub_subscription.default_subscription.id # Full subscription ID
        }
        env {
          name  = "TARGET_GCS_BUCKET_NAME"
          value = google_storage_bucket.target_bucket.name
        }
        env {
          name  = "EXPECTED_MESSAGES_COUNT"
          value = "10" # Or make this a variable if it changes often
        }
        env {
          name  = "OUTPUT_GCS_FILENAME"
          value = "aggregated_job_output.json" # Or make this a variable
        }
      }
    }
  }

  # Optional: Annotations and labels
  # labels = {
  #   environment = "dev"
  # }

  # depends_on is implicitly handled by referencing the service account email.
  # However, explicit dependencies on IAM bindings can be added if needed for strict ordering.
  depends_on = [
    google_project_iam_member.cr_job_sa_pubsub_subscriber,
    google_project_iam_member.cr_job_sa_storage_object_admin
  ]
}