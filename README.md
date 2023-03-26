# Distributed version of the Spring PetClinic Sample Application hosted on K8s with Istio Service Mesh

This project is fork from [Spring PetClinic Microservice project](https://github.com/spring-petclinic/spring-petclinic-microservices) to demonstrate how to use [Istio Service Mesh](https://istio.io) on Kubernetes. While running on Kubernetes and Istio, some components (such as Spring Cloud Config and Eureka Service Discovery) are removed. Additionally, small refactor was done to remove the dependencies and tools which are not relevant to this use case.

## Introduction

The project presents the way how the Service Mesh (in this case [Istio](https://istio.io/)) can be used to manage the communication between microservices and how to use different service mesh features. 

The Spring PetClinic application can be run on two different environments:
* locally, using [Kind (Kubernetes in Docker)](https://kind.sigs.k8s.io/)
* on the cloud, using [GKE (Google Kubernetes Engine)](https://cloud.google.com/kubernetes-engine/docs/concepts/kubernetes-engine-overview)

and Istio installed on top of it with the additional tools (Prometheus, Grafana, Kiali) to monitor the application. 

### Pre-requisites

To build the application you need:
* Java 17
* Maven >=3.6.3

To deploy the application on Kind you need:
* Docker
* [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/)

To run the application on GCP you need:
* Terraform (tested with v1.3.3)
* gcloud
* the GCP project with specific permissions 

#### Kind setup

To build, create docker images and deploy PetClinic application on Kind follow below steps:

1. Go to the project root folder
2. Run the following command:

```
bash ops/scripts/kind/setup-kind-enviornment.sh 
```

This command is responsible for:
* building the application 
* creating docker images
* creating Kind cluster
* installing infrastructure components on the cluster (Istio, Prometheus, Grafana, Kiali)
* deploying the application on the cluster

#### GCP setup
To build, create docker images and deploy PetClinic application on GCP follow below steps:

1. In the `ops/gcp/terraform` folder create the `terraform.tfvars` file with the following content:

```
project_id                        = "gcp_project_id"
region                            = "gcp_region"
gke_zone                          = "gcp_zone"
```
<i>you can override other default values for the variables in the `terraform.tfvars` file</i>

2. Configure `gcloud` 

Terraform is using Google Cloud SDK to authenticate to GCP. To configure gcloud run the following command:

```
google auth application-default login
```

4. Run the following command:

```
bash ops/scripts/gcp/setup-gcp-environment.sh 
```
This command is responsible for:
* creating GCP infrastructure (VPC, subnets, GKE cluster) using Terraform
* building the application
* creating the docker images
* installing infrastructure components on the GKE cluster (Istio, Prometheus, Grafana, Kiali)
* deploying the application on the cluster
