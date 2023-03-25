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

resource "google_compute_address" "gke_lb_public_ip" {
  project      = var.project_id
  name         = var.gke_lb_public_ip_name
  address_type = "EXTERNAL"
  region       = google_compute_subnetwork.subnet.region
  description  = "Pet-Clinic GKE LB public IP managed by Terraform"
}

resource "google_compute_router" "cloud_router" {
  project     = var.project_id
  name        = var.cloud_nat_router_name
  region      = var.region
  network     = google_compute_network.vpc.name
  description = "Pet-Clinic Terraform managed cloud router"

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "cloud_nat" {
  project                            = var.project_id
  name                               = var.cloud_nat_name
  router                             = google_compute_router.cloud_router.name
  region                             = google_compute_router.cloud_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}


# https://istio.io/latest/docs/setup/platform-setup/gke/?_ga=2.261840325.911949839.1679516242-35280436.1676814258#:~:text=For%20private%20GKE%20clusters
data "external" "fetch_gke_node_tag" {
  program = ["bash", "${path.module}/scripts/get_gke_nodes_tag.sh"]
  query = {
    project_id = var.project_id
    gke_cluster_name = google_container_cluster.gke_cluster.name
  }
  depends_on = [google_container_node_pool.gke_node_pool]
}

resource "google_compute_firewall" "istio_webhook_master" {
  name    = "gke-${var.gke_cluster_name}-istio-webhook-master"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports = [15017]
  }

  source_ranges = [var.gke_master_cidr_range]
  target_tags = [data.external.fetch_gke_node_tag.result["gke_nodes_tag"]]

  depends_on = [data.external.fetch_gke_node_tag]
}
