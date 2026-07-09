# NGINX Gateway Fabric Examples

This folder contains examples of exposing GraphDB using the [NGINX Gateway Fabric](https://docs.nginx.com/nginx-gateway-fabric/),
which implements the Kubernetes Gateway API.

## Prerequisites

Install NGINX Gateway Fabric in your cluster:

```bash
kubectl apply -f https://github.com/nginx/nginx-gateway-fabric/releases/download/v1.4.0/crds.yaml
kubectl apply -f https://github.com/nginx/nginx-gateway-fabric/releases/download/v1.4.0/nginx-gateway.yaml
```

## Examples

* [values.yaml](values.yaml) — Deploy and expose GraphDB over HTTP.
* [values_context_path.yaml](values_context_path.yaml) — Deploy GraphDB behind the context path `/graphdb`.
  The URL rewrite is applied automatically when a non-root context path is set in `externalUrl`.
* [values_https.yaml](values_https.yaml) — Deploy and expose GraphDB over HTTPS with TLS termination at the Gateway.
* [values_tls_passthrough.yaml](values_tls_passthrough.yaml) — Deploy GraphDB with TLS passthrough via a
  TLSRoute; GraphDB terminates TLS itself. Requires the Gateway API experimental channel CRDs.
* [values_cluster.yaml](values_cluster.yaml) — Deploy a GraphDB cluster and expose its gRPC inter-node
  port externally via a GRPCRoute. Requires a GraphDB Enterprise Edition license.
