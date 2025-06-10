output "source_gcs_bucket_name" {
  description = "Name of the GCS bucket for source files."
  value       = google_storage_bucket.source_bucket.name
}

output "target_gcs_bucket_name" {
  description = "Name of the GCS bucket for processed/target files."
  value       = google_storage_bucket.target_bucket.name
}

output "terraform_state_bucket_name" {
  description = "Name of the GCS bucket storing the Terraform state."
  value       = google_storage_bucket.terraform_state_bucket.name
}

output "function_source_gcs_bucket_name" {
  description = "Name of the GCS bucket holding the Cloud Function source code."
  value       = google_storage_bucket.function_source_bucket.name
}

output "pubsub_topic_name_full" {
  description = "Full name of the Pub/Sub topic created (projects/PROJECT_ID/topics/TOPIC_ID)."
  value       = google_pubsub_topic.default_topic.id
}

output "pubsub_topic_name_short" {
  description = "Short name (ID) of the Pub/Sub topic created."
  value       = google_pubsub_topic.default_topic.name
}

output "pubsub_subscription_name_full" {
  description = "Full name of the Pub/Sub subscription created."
  value       = google_pubsub_subscription.default_subscription.id
}

    output "pubsub_subscription_name_short" {
      description = "Short name (ID) of the Pub/Sub subscription created."
      value       = google_pubsub_subscription.default_subscription.name
    }
    
output "cloud_function_name" {
  description = "Name of the deployed Cloud Function."
  value       = google_cloudfunctions2_function.default_function.name
}

output "cloud_function_service_account_email" {
  description = "Email of the service account used by the Cloud Function."
  value       = google_service_account.cf_sa.email
}

output "cloud_run_job_name" {
  description = "Name of the deployed Cloud Run Job for the subscriber."
  value       = google_cloud_run_v2_job.subscriber_job.name
}

output "cloud_run_job_service_account_email" {
  description = "Email of the service account used by the Cloud Run Job."
  value       = google_service_account.cr_job_sa.email
}