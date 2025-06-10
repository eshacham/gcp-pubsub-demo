terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0" # Using a recent version
    }
  }

      backend "gcs" {
        bucket = "" # This will be set by -backend-config in CI
        prefix = "pubsub_demo/terraform.tfstate" # Path within the bucket for this project's state
      }

  required_version = ">= 1.0"
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}