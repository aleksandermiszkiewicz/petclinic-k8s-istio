output "gke_lb_public_ip" {
  value = google_compute_global_address.gke_lb_public_ip.address
}

output "gke_name" {
  value = google_container_cluster.gke_cluster.name
}

output "gke_zone" {
  value = google_container_cluster.gke_cluster.location
}

output "project_id" {
  value = var.project_id
}
