#!/bin/bash

base_dir=$(dirname $0)
echo $base_dir

# Creating Kind cluster
if [[ -z "$(kind get clusters | grep petclinic)" ]]; then
  kind create cluster --name petclinic --config "$base_dir"/kind-cluster-config.yml
fi;
kubectl config set-context kind-petclinic

source "$base_dir"/install-infra-resources.sh

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


