#!/bin/bash

eval "$(jq -r 'to_entries[] | "\(.key | ascii_upcase)=\(.value | @sh)"')"
eval "$(jq -r '@sh "GKE_CLUSTER_NAME=\(.gke_cluster_name)"')"
eval "$(jq -r '@sh "PROJECT_ID=\(.project_id)"')"

function error_exit() {
  echo "$1" 1>&2
  exit 1
}

function check_deps() {
  jq_test=$(which jq)
  if [[ -z $jq_test ]]; then error_exit "JQ binary not found"; fi
}

function fetch_gke_nodes_tag() {
  gke_nodes_tag=$(gcloud compute firewall-rules list --filter=name~gke-$GKE_CLUSTER_NAME-[0-9a-z]*-master --format=json --project=$PROJECT_ID | jq '.[0].targetTags[0]')
  jq -n --arg gke_nodes_tag "$gke_nodes_tag" '{"gke_nodes_tag":'$gke_nodes_tag'}'
}


check_deps
fetch_gke_nodes_tag
