resource "google_artifact_registry_repository" "pet_clinic_repo" {
  project       = var.project_id
  location      = var.region
  repository_id = var.artifact_registry_repository_name
  description   = "Pet-Clinic Artifact Registry repository"
  format        = "DOCKER"
}
