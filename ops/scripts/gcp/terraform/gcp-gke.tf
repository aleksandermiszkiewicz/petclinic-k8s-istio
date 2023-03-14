resource "google_service_account" "service_account" {
  project    = var.project_id
  account_id = var.gke_service_account
}

resource "google_container_cluster" "gke_cluster" {
  project    = var.project_id
  name       = var.gke_cluster_name
  location   = var.gke_zone
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  remove_default_node_pool = true
  initial_node_count       = 1

  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    master_ipv4_cidr_block = "10.100.0.0/28"
  }

  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_ipv4_cidr_block = "10.101.0.0/21"
    services_ipv4_cidr_block = "10.102.0.0/21"
  }

  release_channel {
    channel = "STABLE"
  }
}

resource "google_container_node_pool" "gke_node_pool" {
  project    = var.project_id
  name       = var.gke_node_pool_name
  location   = var.gke_zone
  cluster    = google_container_cluster.gke_cluster.name
  node_count = var.gke_node_pool_nodes_count

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append"
    ]

    machine_type = "e2-medium"
    disk_type    = "pd-standard"
    disk_size_gb = 30
    image_type   = "COS_CONTAINERD"

    metadata     = {
      disable-legacy-endpoints = "true"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
