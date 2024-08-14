# Azure Service Account Examples

This folder contains examples of using GraphDB with the Service account to gain access to the Azure services.

The main reason that we want to use service accounts is that GraphDB relies on Azure Storage Account 
for the Cloud Backups. But you can use that service account to use other Azure services from the AKS cluster as well,
when you have configured your IAM Role Assignments properly.

## Pre-requisites

* AKS Cluster: Ensure you have an AKS cluster up and running.
* Before starting with the service account setup you should have an IAM Role assignment that should 
  have access to the Azure Storage Account Service.
* [Best practices for authentication and authorization in Azure Kubernetes Service (AKS)](https://learn.microsoft.com/en-us/azure/aks/operator-best-practices-identity)
* [Azure Login using identity](https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli-managed-identity)
* [Deploy and configure workload identity on an Azure Kubernetes Service (AKS) cluster](https://learn.microsoft.com/en-us/azure/aks/workload-identity-deploy-cluster)
* [Azure Role Assignments](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal)

## Example

* [values.yaml](values.yaml) - Example of how to deploy the service account.
