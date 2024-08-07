# Overview 

This document describes the steps on how to configure the GraphDB Helm chart to use Ingress on AWS EKS.

## Prerequisites

* EKS Cluster: Ensure you have an EKS cluster up and running.
* [Installing AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.8/deploy/installation/)
* [Ingress Setup](https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html)
* [Ingress Class](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/guide/ingress/ingress_class/)
* [Exposing kubernetes applications via ingress](https://aws.amazon.com/blogs/containers/exposing-kubernetes-applications-part-1-service-and-ingress-resources/)

## Example

* [values.yaml](values.yaml) - Example of how to deploy and expose GraphDB with Ingress without SSL enabled.
* [values_https.yaml](values_https.yaml) - Example of how to deploy and expose GraphDB with Ingress with SSL enabled.

## Note

After you deploy and the ingress is created please change the externalUrl value to the DNS name of the ALB or Route53.
