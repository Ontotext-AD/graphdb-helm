# AKS Application Gateway Ingress deployment

This document describes the steps on how to configure the GraphDB Helm chart to use Application Gateway Ingress on Azure AKS.

## Prerequisites

* AKS Cluster: Ensure you have an AKS cluster up and running.
* [Enable application gateway ingress on existing AKS cluster](https://learn.microsoft.com/en-us/azure/application-gateway/tutorial-ingress-controller-add-on-new)
* [Application Gateway supported annotations](https://azure.github.io/application-gateway-kubernetes-ingress/annotations/)

## Example

* [values.yaml](values.yaml) - Example of how to deploy and expose GraphDB with Ingress without SSL enabled.
* [values_https.yaml](values_https.yaml) - Example of how to deploy and expose GraphDB with Ingress with SSL enabled.

## Note

After you deploy the GraphDB chart you should either point an DNS name to the Application Gateway and set 
the externalUrl property in the chart and re-apply it, or the other option you can use nip.io and map it's 
public ip address to nip.io. In order to do that use the kubectl get ingress commands and copy the Public IP 
for the GraphDB ingress, then go to the values file and set the externalUrl property to http://ip.address.nip.io/. 
Otherwise Workbench won't be accessible.
