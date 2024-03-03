provider "google" {
  project = "qwiklabs-gcp-04-492aa8407ae2"
  region  = "us-central1"
}

resource "google_storage_bucket" "test-bucket-for-state" {
  name                        = "qwiklabs-gcp-04-492aa8407ae2"
  location                    = "US" # Replace with EU for Europe region
  uniform_bucket_level_access = true
  force_destroy               = true
}

terraform {
  backend "gcs" {
    bucket = "qwiklabs-gcp-04-492aa8407ae2"
    prefix = "terraform/state"
  }
}
