#!/bin/bash

base_dir=$(dirname $0)

# Build infrastructure
terraform -chdir=$base_dir/terraform init

terraform -chdir=$base_dir/terraform apply --auto-approve

project_id=$(terraform -chdir=$base_dir/terraform output -raw project_id)
gke_lb_public_ip=$(terraform -chdir=$base_dir/terraform output -raw gke_lb_public_ip)
gke_name=$(terraform -chdir=$base_dir/terraform output -raw gke_name)
gke_zone=$(terraform -chdir=$base_dir/terraform output -raw gke_zone)

echo "GKE name -> $gke_name"
echo "GKE LB Public IP -> $gke_lb_public_ip"

# creation of infra services configs
yq "
  .service.loadBalancerIP = $gke_lb_public_ip |
  .service.type = LoadBalancer
  " ops/templates/istio-gateway-template.yaml > "$base_dir"/istio-gateway-overrides.yaml
yq ".cr.spec.external-services.grafana.url = http://$gke_lb_public_ip:3000" ops/scripts/templates/kiali-operator-template.yaml > "$base_dir"/kiali-operator-overrides.yaml
yq ops/scripts/templates/kube-prometheus-stack-template.yaml > "$base_dir"/kube-prometheus-stack-overrides.yaml

# authenticate to cluster
gcloud container clusters get-credentials "$gke_name" --project "$project_id" --zone "$gke_zone"

# deploy infra
istio_version=1.17.1
kiali_version=1.64
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

helm upgrade --install kiali-operator kiali/kiali-operator \
  -n kiali-operator \
  --create-namespace \
  --version $kiali_version \
  --values "$base_dir"/kiali-operator-overrides.yaml

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  -n prometheus \
  --create-namespace \
  --version $kube_prometheus_stack_version \
  --values "$base_dir"/kube-prometheus-stack-overrides.yaml

echo "Build project"
./mvnw clean install

echo "Build images"
./mvnw -Dmaven.test.skip=true -DGCP_PROJECT_ID=$project_id -DAPP_VERSION=1.0.0 package jib:dockerBuild -Pgcp,buildDocker
