resource "google_pubsub_topic" "default_topic" {
  name    = var.pubsub_topic_id
  project = var.gcp_project_id
}

resource "google_pubsub_subscription" "default_subscription" {
  name    = var.pubsub_subscription_id
  topic   = google_pubsub_topic.default_topic.name # Uses the name of the topic created above
  project = var.gcp_project_id

  ack_deadline_seconds = 30 # Default is 10. Increase if message processing takes longer.

  # Message retention duration (default is 7 days)
  # message_retention_duration = "604800s" # 7 days in seconds

  # Retry policy (optional)
  # retry_policy {
  #   minimum_backoff = "10s"
  # }
}