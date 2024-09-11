# Overview

This document describes the steps on how to configure the GraphDB Helm chart to use Ingress on GCP GKE.

## Prerequisites

* Ensure you have a GKE cluster up and running.
* [GKE Ingress controller behavior](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress#controller_summary)
* [Ingress Setup](https://cloud.google.com/kubernetes-engine/docs/tutorials/http-balancer)
* [Ingress Setup with SSL enabled using Google-managed certificate](https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs#creating_an_ingress_with_a_google-managed_certificate)

## Example

* [values.yaml](values.yaml) - Example of how to deploy and expose GraphDB with Ingress without SSL enabled.
* [values_https.yaml](values_https.yaml) - Example of how to deploy and expose GraphDB with Ingress with SSL enabled.

## Note

After you deploy the GraphDB chart you should either point a DNS name to the Google Ingress and set
the externalUrl property in the chart and re-apply it, or the other option you can use nip.io and map it's
public ip address to nip.io. In order to do that use the kubectl get ingress commands and copy the Public IP
for the GraphDB ingress, then go to the values file and set the externalUrl property to http://ip.address.nip.io/.
Otherwise Workbench won't be accessible.
