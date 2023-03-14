#!/bin/bash

# Build infrastructure
base_dir=$(dirname $0)
echo $base_dir

kubectl delete -k ops/gcp/overlays/gcp

helm uninstall prometheus -n prometheus
helm uninstall kiali-operator -n kiali-operator
helm uninstall istio-ingressgateway -n istio-ingress
helm uninstall istiod -n istio-system
helm uninstall istio-base -n istio-base

terraform -chdir=$base_dir/terraform destroy --auto-approve
