variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "vpc_name" {
  type        = string
  description = "Pet-Clinic VPC name"
  default     = "pet-clinic-vpc"
}

variable "subnet_name" {
  type        = string
  description = "Pet-Clinic subnet name"
  default     = "pet-clinic-subnet"
}

variable "region" {
  type        = string
  description = "Pet-Clinic infra region"
  default     = "europe-west1"
}

variable "gke_cluster_name" {
  type        = string
  description = "Pet-Clinic Terraform managed cluster"
  default     = "pet-clinic-cluster"
}

variable "gke_zone" {
  type        = string
  description = "Pet-Clinic GKE cluster zone (zonal cluster will be created)"
  default     = "europe-west1-b"
}

variable "gke_node_pool_name" {
  type        = string
  description = "Pet-Clinic Terraform managed node pool"
  default     = "pet-clinic-np"
}

variable "gke_node_pool_nodes_count" {
  type        = string
  description = "Pet-Clinic node pool nodes count"
  default     = 2
}

variable "gke_node_pool_min_nodes_count" {
  type = string
  description = "Pet-Clinic node pool minimum nodes count"
  default = 3
}

variable "gke_node_pool_max_nodes_count" {
  type = string
  description = "Pet-Clinic node pool maximum nodes count"
  default = 5
}

variable "gke_service_account" {
  type        = string
  description = "Pet-Clinic node pool service account"
  default     = "pet-clinic-sa"
}

variable "gke_lb_public_ip_name" {
  type        = string
  description = "Pet-Clinic GKE LB Public IP name"
  default     = "pet-clinic-gke-lb-ip"
}

variable "gke_master_cidr_range" {
  type = string
  description = "Pet-Clinic GKE master CIDR range"
  default = "10.100.0.0/28"
}

variable "cloud_nat_router_name" {
  type = string
  description = "Pet-Clinic Cloud Router for NAT name"
  default = "pet-clinic-cloud-router"
}

variable "cloud_nat_name" {
  type = string
  description = "Pet-Clinic Cloud NAT name"
  default = "pet-clinic-cloud-nat"
}

variable "artifact_registry_repository_name" {
  type = string
  description = "Pet-Clinic Artifact registry repository name"
  default = "pet-clinic"
}
