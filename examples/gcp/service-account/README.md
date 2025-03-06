# GCP Service Account Example

This folder contains examples of using GraphDB with a GCP Service Account to gain access to Google Cloud services.

The main reason for using a Service Account is that GraphDB relies on Google Cloud Storage for cloud backups.  
However, the same service account can be used for accessing other GCP services when properly configured   
with IAM roles and permissions.

## **Granting Resource Access**

There are two main ways to grant access to Google Cloud resources from Kubernetes:

1. Workload Identity Federation – Grants an IAM role to a Kubernetes ServiceAccount so it can directly access Google
   Cloud resources without requiring service account keys.
2. IAM Service Account Impersonation – Grants an IAM role to a Google service account and allows workloads to
   impersonate it.

This example focuses on the second approach: IAM Service Account Impersonation

## Pre-requisites

* GKE Cluster: Ensure you have a GKE cluster up and running
  with [Workload Identity Federation enabled](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#enable_on_clusters_and_node_pools).
* [Link Kubernetes ServiceAccounts to IAM](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#kubernetes-sa-to-iam).

## How to use

Once the IAM allow policy is created, you can simply use the provided `values.yaml` file to annotate
the Kubernetes ServiceAccount
(default name: `graphdb`). This will allow it to function as expected.

## Example

* [values.yaml](values.yaml) - Example of how to deploy the service account.
