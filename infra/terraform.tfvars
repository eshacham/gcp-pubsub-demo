// infra/terraform.tfvars
gcp_project_id = "pubsub-demo-0518" // Replace with your actual GCP Project ID
// gcp_region     = "us-east1" // Optional: if you want to override the default in variables.tf
subscriber_docker_image = "gcr.io/pubsub-demo-0518/pubsub-gcs-subscriber:latest" // Or your Artifact Registry path

