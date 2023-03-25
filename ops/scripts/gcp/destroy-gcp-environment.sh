#!/bin/bash

base_dir=$(dirname $0)

function destroy_app() {
  kubectl delete -k ops/k8s/overlays/gke/base
}

function authenticate_to_gke() {
  project_id=$(terraform -chdir="$base_dir"/terraform output -raw project_id)
  gke_name=$(terraform -chdir="$base_dir"/terraform output -raw gke_name)
  gke_zone=$(terraform -chdir="$base_dir"/terraform output -raw gke_zone)
  gcloud container clusters get-credentials "$gke_name" --project "$project_id" --zone "$gke_zone"
}

function destroy_infra_resources_on_gke() {
  helm uninstall prometheus -n prometheus
  helm uninstall kiali-operator -n kiali-operator
  helm uninstall istio-ingressgateway -n istio-ingress
  helm uninstall istiod -n istio-system
  helm uninstall istio-base -n istio-base
}

function destroy_infra() {
  terraform -chdir=$base_dir/terraform destroy --auto-approve
}

authenticate_to_gke
destroy_app
destroy_infra_resources_on_gke
destroy_infra
