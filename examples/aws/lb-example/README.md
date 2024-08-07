# EKS Load Balancer Type Deployment

This folder contains examples of using GraphDB with the AWS Network Load Balancer.

## Pre-requisites 

* EKS Cluster: Ensure you have an EKS cluster up and running.
* [Installing AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.8/deploy/installation/)
* [AWS Documentation - Route TCP and UDP traffic with Network Load Balancers](https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html)

## Example

* [values.yaml](values.yaml) - Example of how to deploy and expose GraphDB with Network Load Balancer without SSL enabled.
* [values_https.yaml] - Example of how to deploy and expose GraphDB with Network Load Balancer with SSL enabled.