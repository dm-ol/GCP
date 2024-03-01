terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

provider "google" {

  project = "qwiklabs-gcp-03-139247df6686"
  region  = "us-central1"
  zone    = "us-central1-a"
}

resource "google_compute_instance" "terraform" {
  name         = "terraform"
  machine_type = "e2-medium"
  tags         = ["web", "dev"]
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network = "default"
    access_config {
    }
  }
  allow_stopping_for_update = true # To ensure the VM stops before updating the machine_type, set allow_stopping_for_update argument to true
