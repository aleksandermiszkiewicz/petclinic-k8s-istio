#!/bin/bash

set -e errexit

base_dir=$(dirname $0)

function deploy_cloud_infra() {
  echo "============================="
  echo "Deploy infrastructure to GCP"
  echo "============================="
  terraform -chdir=$base_dir/terraform init
  terraform -chdir=$base_dir/terraform apply --auto-approve
  sleep 30
}

function fetch_infra_outputs() {
  echo "============================="
  echo "Get outputs from terraform"
  echo "============================="
  project_id=$(terraform -chdir="$base_dir"/terraform output -raw project_id)
  gke_lb_public_ip=$(terraform -chdir="$base_dir"/terraform output -raw gke_lb_public_ip)
  gke_name=$(terraform -chdir="$base_dir"/terraform output -raw gke_name)
  gke_zone=$(terraform -chdir="$base_dir"/terraform output -raw gke_zone)
  artifact_registry_region=$(terraform -chdir="$base_dir"/terraform output -raw artifact_registry_region)
  artifact_registry_repo=$(terraform -chdir="$base_dir"/terraform output -raw artifact_registry_repo)

  echo "GCP Project ID -> $project_id"
  echo "GKE name -> $gke_name"
  echo "GKE LB Public IP -> $gke_lb_public_ip"
  echo "GKE Zone -> $gke_zone"
}

function configure_infra_deployments() {
  echo "============================="
  echo "Create overrides for istio, kiali and prometheus"
  echo "============================="

  yq ".service.loadBalancerIP = \"$gke_lb_public_ip\"" ops/scripts/templates/istio-gateway-template.yaml > "$base_dir"/istio-gateway-overrides.yaml
  yq ".cr.spec.external-services.grafana.url = \"http://$gke_lb_public_ip:3000\"" ops/scripts/templates/kiali-operator-template.yaml > "$base_dir"/kiali-operator-overrides.yaml
  yq ops/scripts/templates/kube-prometheus-stack-template.yaml > "$base_dir"/kube-prometheus-stack-overrides.yaml
}

function authenticate_to_gke() {
  echo "============================="
  echo "Authenticate to GKE"
  echo "============================="
  gcloud container clusters get-credentials "$gke_name" --project "$project_id" --zone "$gke_zone"
}

function deploy_infra_resources_on_gke() {
  echo "============================="
  echo "Deploy infra resources on GKE"
  echo "============================="
  istio_version=1.17.1
  kiali_version=1.65
  kube_prometheus_stack_version=45.6.0

  helm repo add istio https://istio-release.storage.googleapis.com/charts
  helm repo add kiali https://kiali.org/helm-charts
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo update

  helm upgrade --install istio-base istio/base \
    -n istio-system \
    --create-namespace \
    --version "$istio_version"

  helm upgrade --install istiod istio/istiod \
    -n istio-system \
    --version "$istio_version"

  helm upgrade --install istio-ingressgateway istio/gateway \
    -n istio-ingress \
    --version "$istio_version" \
    --create-namespace \
    --values "$base_dir"/istio-gateway-overrides.yaml

  helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    -n prometheus \
    --create-namespace \
    --version "$kube_prometheus_stack_version" \
    --values "$base_dir"/kube-prometheus-stack-overrides.yaml

  helm upgrade --install kiali-operator kiali/kiali-operator \
    -n kiali-operator \
    --create-namespace \
    --version "$kiali_version" \
    --values "$base_dir"/kiali-operator-overrides.yaml

}

function build_docker_images() {
  echo "============================="
  echo "Build Pet-Clinic application"
  echo "============================="
  ./mvnw clean install

  echo "============================="
  echo "Build Pet-Clinic application docker images"
  echo "============================="

  ./mvnw -Dmaven.test.skip=true -DGCP_PROJECT_ID=$project_id -DGCP_ACR_LOCATION=$artifact_registry_region -DGCP_ACR_REPOSITORY=$artifact_registry_repo -DAPP_VERSION=1.0.0 package jib:dockerBuild -Pgcp,buildDocker
}

function push_images_to_gcp_ar() {
  echo "============================="
  echo "Push Pet-Clinic application docker images to GCP AR"
  echo "============================="

  yes Y | gcloud auth configure-docker "$artifact_registry_region"-docker.pkg.dev --project "$project_id"
  docker push "$artifact_registry_region"-docker.pkg.dev/"$project_id"/"$artifact_registry_repo"/spring-petclinic-admin-server:1.0.0
  docker push "$artifact_registry_region"-docker.pkg.dev/"$project_id"/"$artifact_registry_repo"/spring-petclinic-api-gateway:1.0.0
  docker push "$artifact_registry_region"-docker.pkg.dev/"$project_id"/"$artifact_registry_repo"/spring-petclinic-customers-service:1.0.0
  docker push "$artifact_registry_region"-docker.pkg.dev/"$project_id"/"$artifact_registry_repo"/spring-petclinic-vets-service:1.0.0
  docker push "$artifact_registry_region"-docker.pkg.dev/"$project_id"/"$artifact_registry_repo"/spring-petclinic-visits-service:1.0.0
}

function deploy_pet_clinic() {
  echo "============================="
  echo "Deploy Pet-Clinic application to GKE"
  echo "============================="

  yq '
    .images[0] += {"newName": "'"$artifact_registry_region"'-docker.pkg.dev/'"$project_id"'/'"$artifact_registry_repo"'/spring-petclinic-admin-server"} |
    .images[1] += {"newName": "'"$artifact_registry_region"'-docker.pkg.dev/'"$project_id"'/'"$artifact_registry_repo"'/spring-petclinic-api-gateway"} |
    .images[2] += {"newName": "'"$artifact_registry_region"'-docker.pkg.dev/'"$project_id"'/'"$artifact_registry_repo"'/spring-petclinic-customers-service"} |
    .images[3] += {"newName": "'"$artifact_registry_region"'-docker.pkg.dev/'"$project_id"'/'"$artifact_registry_repo"'/spring-petclinic-vets-service"} |
    .images[4] += {"newName": "'"$artifact_registry_region"'-docker.pkg.dev/'"$project_id"'/'"$artifact_registry_repo"'/spring-petclinic-visits-service"}
    ' -i ops/k8s/overlays/gke/base/kustomization.yaml

  kubectl apply -k ops/k8s/overlays/gke/base
}


deploy_cloud_infra
fetch_infra_outputs
configure_infra_deployments
authenticate_to_gke
deploy_infra_resources_on_gke
build_docker_images
push_images_to_gcp_ar
deploy_pet_clinic
