resource "random_id" "bucket_hex" {
  byte_length = 4 # Creates an 8-character hex string for uniqueness
}

resource "google_storage_bucket" "source_bucket" {
  name                        = "${var.gcp_project_id}-${var.source_bucket_name_suffix}-${random_id.bucket_hex.hex}"
  location                    = var.gcp_region # For regional buckets; use "US" or other multi-region for multi-regional.
  uniform_bucket_level_access = true
  project                     = var.gcp_project_id
}

resource "google_storage_bucket" "target_bucket" {
  name                        = "${var.gcp_project_id}-${var.target_bucket_name_suffix}-${random_id.bucket_hex.hex}"
  location                    = var.gcp_region
  uniform_bucket_level_access = true
  project                     = var.gcp_project_id
}

resource "google_storage_bucket" "terraform_state_bucket" {
  name                        = "${var.gcp_project_id}-${var.state_bucket_name_suffix}-${random_id.bucket_hex.hex}"
  location                    = var.gcp_region # State bucket should ideally be regional for lower latency
  uniform_bucket_level_access = true
  project                     = var.gcp_project_id
  versioning {                # Enable versioning for safety
    enabled = true
  }
}
# Bucket for Cloud Function source code
resource "google_storage_bucket" "function_source_bucket" {
  name                        = "${var.gcp_project_id}-cf-source-${random_id.bucket_hex.hex}"
  location                    = var.gcp_region # Functions are regional, so source bucket can be too.
  uniform_bucket_level_access = true
  project                     = var.gcp_project_id
}

data "archive_file" "function_source_zip" {
  type        = "zip"
  source_dir  = abspath(var.function_source_dir) # Use absolute path for source_dir
  output_path = "function_source_${var.cloud_function_name}.zip" # Output to current working directory
}

resource "google_storage_bucket_object" "function_source_archive" {
  name   = "source-${data.archive_file.function_source_zip.output_md5}.zip" # Include hash for auto-redeploy on change
  bucket = google_storage_bucket.function_source_bucket.name
  source = data.archive_file.function_source_zip.output_path # Path to the zipped function source
}