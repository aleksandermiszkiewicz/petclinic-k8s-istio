terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.21.0"
    }
  }

  required_version = ">= 1.3.0"
}

provider "google" {
  project = var.project_id
}
