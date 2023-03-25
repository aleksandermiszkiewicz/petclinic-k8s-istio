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
    master_ipv4_cidr_block = var.gke_master_cidr_range
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

  node_config {
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    machine_type = "e2-standard-2"
    disk_type    = "pd-standard"
    disk_size_gb = 30
    image_type   = "COS_CONTAINERD"

    metadata     = {
      disable-legacy-endpoints = "true"
    }

    preemptible = true
  }

  autoscaling {
    max_node_count = var.gke_node_pool_max_nodes_count
    min_node_count = var.gke_node_pool_min_nodes_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

resource  "google_project_iam_binding" log_writer {
    project = var.project_id
    role    = "roles/logging.logWriter"

    members = [
        "serviceAccount:${google_service_account.service_account.email}",
    ]
}

resource  "google_project_iam_binding" metric_writer {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"

  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

resource "google_project_iam_binding" monitoring_viewer {
    project = var.project_id
    role    = "roles/monitoring.viewer"

    members = [
        "serviceAccount:${google_service_account.service_account.email}",
    ]
}
