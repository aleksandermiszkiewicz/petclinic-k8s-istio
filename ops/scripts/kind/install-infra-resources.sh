#!/bin/bash
base_dir=$(dirname $0)
echo $base_dir

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
  --values "$base_dir"/kube-prometheus-stack-overrides.yml
