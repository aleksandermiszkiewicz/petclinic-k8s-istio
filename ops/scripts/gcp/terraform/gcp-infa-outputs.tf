output "gke_lb_public_ip" {
  value = google_compute_address.gke_lb_public_ip.address
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

output "artifact_registry_region" {
  value = google_artifact_registry_repository.pet_clinic_repo.location
}

output "artifact_registry_repo" {
  value = google_artifact_registry_repository.pet_clinic_repo.name
}
