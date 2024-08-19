# AKS Load Balancer type deployment

This folder contains examples of using GraphDB with the Azure Load Balancer.

## Pre-requisites 

* AKS Cluster: Ensure you have an AKS cluster up and running.
* [Use a public standard load balancer in Azure Kubernetes Service (AKS)](https://learn.microsoft.com/en-us/azure/aks/load-balancer-standard)
* [Expose an AKS service over HTTP or HTTPS using Application Gateway](https://learn.microsoft.com/en-us/azure/application-gateway/ingress-controller-expose-service-over-http-https)
* [Azure Kubernetes Service Type Load Balancer supported annotations](https://cloud-provider-azure.sigs.k8s.io/topics/loadbalancer/#loadbalancer-annotations)

## Example

* [values.yaml](values.yaml) - Example of how to deploy and expose GraphDB with Azure Load Balancer.
