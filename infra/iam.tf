# Permissions for the Cloud Function's Service Account (cf_sa)

# Allow the SA to publish messages to the Pub/Sub topic
resource "google_project_iam_member" "cf_sa_pubsub_publisher" {
  project = var.gcp_project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.cf_sa.email}"
}

# Allow the SA to read objects from GCS (specifically the source bucket)
# For more fine-grained control, use google_storage_bucket_iam_member on the source_bucket
resource "google_project_iam_member" "cf_sa_storage_object_viewer" {
  project = var.gcp_project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.cf_sa.email}"
}

# For Cloud Functions (2nd gen), Eventarc triggers the underlying Cloud Run service.
# The function's service account needs to be invokable by Eventarc.
resource "google_project_iam_member" "cf_sa_run_invoker" {
  project = var.gcp_project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.cf_sa.email}"
}

# The function's service account also needs to act as an Eventarc event receiver.
resource "google_project_iam_member" "cf_sa_eventarc_receiver" {
  project = var.gcp_project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.cf_sa.email}"
}

# Permissions for the Google-managed Eventarc Service Agent
# This agent is used by Eventarc to manage resources for triggers.
data "google_project" "project" {
}

resource "google_project_iam_member" "eventarc_service_agent" {
  project = data.google_project.project.project_id
  role    = "roles/eventarc.serviceAgent"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-eventarc.iam.gserviceaccount.com"
}

# Permissions for the Google-managed Cloud Storage Service Agent
# This agent needs to publish notifications from GCS buckets to the Eventarc-managed Pub/Sub topic.
data "google_storage_project_service_account" "gcs_service_account" {
  project = var.gcp_project_id
}

resource "google_project_iam_member" "gcs_service_agent_pubsub_publisher" {
  project = var.gcp_project_id
  role    = "roles/pubsub.publisher" # Allows GCS to publish to the Eventarc topic
  member  = "serviceAccount:${data.google_storage_project_service_account.gcs_service_account.email_address}"
}

# Permissions for the Cloud Run Job's Service Account (cr_job_sa)

# Allow the SA to subscribe to the Pub/Sub subscription
resource "google_project_iam_member" "cr_job_sa_pubsub_subscriber" {
  project = var.gcp_project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.cr_job_sa.email}"
}

# Allow the SA to create/overwrite objects in the target GCS bucket.
# Granting at project level for simplicity here, but ideally scope to the specific bucket.
# For bucket-level: google_storage_bucket_iam_member
resource "google_project_iam_member" "cr_job_sa_storage_object_admin" {
  project = var.gcp_project_id
  role    = "roles/storage.objectAdmin" # Includes create, delete, get, list
  member  = "serviceAccount:${google_service_account.cr_job_sa.email}"
}

# Cloud Run Job service account also needs to be able to be assumed by Cloud Run execution service
resource "google_project_iam_member" "cr_job_sa_token_creator" {
  project = var.gcp_project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.cr_job_sa.email}"
}

# Allow the Cloud Function's Service Account (cf_sa) to invoke/run the Cloud Run Job
resource "google_cloud_run_v2_job_iam_member" "cf_sa_can_run_subscriber_job" {
  project  = var.gcp_project_id
  location = var.gcp_region
  name     = google_cloud_run_v2_job.subscriber_job.name # Reference the job created in cloudrun.tf
  role     = "roles/run.invoker"                         # This role allows running the job
  member   = "serviceAccount:${google_service_account.cf_sa.email}"
}