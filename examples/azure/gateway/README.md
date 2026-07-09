# Azure Application Gateway for Containers Examples

This folder contains examples of exposing GraphDB using
[Azure Application Gateway for Containers](https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/overview),
Azure's managed implementation of the Kubernetes Gateway API.

## Prerequisites

Not supported on AKS clusters using `kubenet` networking - requires Azure CNI or Azure CNI Overlay.

**Option A: AKS-managed ALB Controller add-on (recommended)** - AKS provisions and manages the
controller for you. Requires an existing AKS cluster with Azure CNI/CNI Overlay, OIDC issuer, and
workload identity enabled:

```bash
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.NetworkFunction
az provider register --namespace Microsoft.ServiceNetworking
az extension add --name alb
az extension add --name aks-preview
az feature register --namespace "Microsoft.ContainerService" --name "ManagedGatewayAPIPreview"
az feature register --namespace "Microsoft.ContainerService" --name "ApplicationLoadBalancerPreview"
az provider register --namespace Microsoft.ContainerService

az aks update --name <cluster-name> --resource-group <resource-group> \
  --enable-oidc-issuer --enable-workload-identity \
  --enable-gateway-api --enable-application-load-balancer
```

With this option, `gatewayApi.gateway.className` must be exactly `azure-alb-external` - the controller
rejects any other GatewayClass name.

**Option B: Self-managed (BYO) ALB Controller** - install the controller yourself via Helm, which lets
you choose your own GatewayClass name for `gatewayApi.gateway.className`:

```bash
az aks install-cli
helm install alb-controller oci://mcr.microsoft.com/application-lb/charts/alb-controller \
  --namespace azure-alb-system \
  --create-namespace \
  --set albController.namespace=azure-alb-system \
  --set albController.podIdentity.clientID=$(az identity show -g <resource-group> -n <identity-name> --query clientId -o tsv)
```

**Both options** require:
- A subnet in the AKS VNet delegated to `Microsoft.ServiceNetworking/trafficControllers` (the add-on
  creates this automatically; BYO requires creating it yourself).
- An `ApplicationLoadBalancer` resource referenced by `gatewayApi.gateway.annotations` (`alb-namespace`/
  `alb-name`), pointing at that subnet.
- Gateway API CRDs, v1.2.0+ (earlier versions lack the `spec.infrastructure` field some examples use):

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
```

## Examples

* [values.yaml](values.yaml) — Deploy and expose GraphDB over HTTP using Application Gateway for Containers.
* [values_https.yaml](values_https.yaml) — Deploy and expose GraphDB over HTTPS with TLS termination.
* [values_cluster.yaml](values_cluster.yaml) — Deploy a GraphDB cluster and expose its gRPC inter-node
  port externally via a GRPCRoute.
