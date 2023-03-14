#!/bin/bash

base_dir=$(dirname $0)

# Creating Kind cluster
if [[ -z "$(kind get clusters | grep petclinic)" ]]; then
  kind create cluster --name petclinic --config "$base_dir"/kind-cluster-config.yml
fi;
kubectl config set-context kind-petclinic

yq '
  .service.ports[0] += {"nodePort": 30000} |
  .service.ports[1] += {"nodePort": 30001} |
  .service.ports[2] += {"nodePort": 30002} |
  .service.ports[3] += {"nodePort": 30003} |
  .service.ports[4] += {"nodePort": 30004} |
  .service.ports[5] += {"nodePort": 30005}' ops/scripts/templates/istio-gateway-template.yaml > $base_dir/istio-gateway-overrides.yaml
yq ops/scripts/templates/kiali-operator-template.yaml > $base_dir/kiali-operator-overrides.yaml
yq ops/scripts/templates/kube-prometheus-stack-template.yaml > $base_dir/kube-prometheus-stack-overrides.yaml

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

export appVersion=1.0.0

echo "Build project"
./mvnw clean install

echo "Build images"
./mvnw -Dmaven.test.skip=true package jib:dockerBuild -PbuildDocker

images=$(docker images "springcommunity/*:${appVersion}" | awk '{if(NR>1) print $1}')

echo "Load images to Kind"
for image in $images; do
  name="${image}:$appVersion"
  kind load docker-image "$name" --name petclinic
  echo "Image $name loaded to kind"
done

kubectl apply -k ops/k8s/overlays/kind


