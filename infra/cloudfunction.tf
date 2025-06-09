resource "google_service_account" "cf_sa" {
  account_id   = substr("cf-${replace(var.cloud_function_name, "_", "-")}-sa", 0, 30) # Ensure valid account_id format
  display_name = "SA for Cloud Function ${var.cloud_function_name}"
  project      = var.gcp_project_id
}

resource "google_cloudfunctions2_function" "default_function" {
  name        = var.cloud_function_name
  location    = var.gcp_region
  project     = var.gcp_project_id
  description = "Publishes GCS file content (JSON list) as individual Pub/Sub messages."

  build_config {
    runtime     = "python311"         # Specify your Python runtime
    entry_point = "gcs_event_handler" # This must match the function name in function_source/main.py
    source {
      storage_source {
        bucket = google_storage_bucket.function_source_bucket.name
        object = google_storage_bucket_object.function_source_archive.name
      }
    }
  }

  service_config {
    max_instance_count = 3       # Adjust as needed
    min_instance_count = 0       # Scale to zero for cost savings
    available_memory   = "256Mi" # Adjust as needed
    timeout_seconds    = 60      # Max 540 for 1st gen, 3600 for 2nd gen HTTP, 60 for event-driven
    environment_variables = {
      GCP_PROJECT_ID  = var.gcp_project_id
      PUBSUB_TOPIC_ID = google_pubsub_topic.default_topic.name # Pass the actual topic name
    }
    ingress_settings               = "ALLOW_ALL" # For GCS (Eventarc) trigger, this is fine. Can be "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
    service_account_email          = google_service_account.cf_sa.email
  }

  event_trigger {
    trigger_region = var.gcp_region # Can be different from function region if needed, but usually same
    event_type     = "google.cloud.storage.object.v1.finalized"
    retry_policy   = "RETRY_POLICY_RETRY" # Or RETRY_POLICY_DO_NOT_RETRY
    # The service account used by Eventarc to invoke the function.
    # This SA (cf_sa) needs roles/run.invoker on the function's underlying Cloud Run service
    # and roles/eventarc.eventReceiver.
    service_account_email = google_service_account.cf_sa.email
    event_filters {
      attribute = "bucket"
      value     = google_storage_bucket.source_bucket.name
    }
  }

  depends_on = [google_project_iam_member.cf_sa_run_invoker] # Ensure SA has invoker role before function creation
}