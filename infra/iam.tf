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