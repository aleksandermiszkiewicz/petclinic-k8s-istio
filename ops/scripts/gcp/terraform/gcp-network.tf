resource "google_compute_network" "vpc" {
  project                 = var.project_id
  name                    = var.vpc_name
  description             = "Pet-Clinic Terraform managed network"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "subnet" {
  project                  = var.project_id
  name                     = var.subnet_name
  region                   = var.region
  network                  = google_compute_network.vpc.id
  description              = "Pet-Clinic Terraform managed subnet"
  ip_cidr_range            = "10.2.0.0/24"
  private_ip_google_access = true
}

resource "google_compute_global_address" "gke_lb_public_ip" {
  project      = var.project_id
  name         = var.gke_lb_public_ip_name
  address_type = "EXTERNAL"
  description  = "Pet-Clinic GKE LB public IP managed by Terraform"
}
