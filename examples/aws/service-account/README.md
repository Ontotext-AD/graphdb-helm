# AWS Service Account Examples

This folder contains examples of using GraphDB with the Service account to gain access to the AWS services.

The main reason that we want to use service accounts is that GraphDB relies on S3 for the Cloud Backups. But you can use that service account to use other AWS services from the EKS cluster as well, 
when you have configured your IAM policies properly.

## Pre-requisites

* EKS Cluster: Ensure you have an EKS cluster up and running.
* Before starting with the service account setup you should have an IAM Role that should have access to the S3 Service.
* [IAM Roles for service accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
* [IAM Policy examples](https://docs.aws.amazon.com/AmazonS3/latest/userguide/example-policies-s3.html)

## Example

* [values.yaml](values.yaml) - Example of how to deploy the service account.

