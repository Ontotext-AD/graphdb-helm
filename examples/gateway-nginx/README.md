# NGINX Gateway Fabric Examples

This folder contains examples of exposing GraphDB using
the [NGINX Gateway Fabric](https://docs.nginx.com/nginx-gateway-fabric/), which implements the Kubernetes Gateway API.

## Prerequisites

Install NGINX Gateway Fabric in your cluster:

```bash
kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v2.8.1" | kubectl apply -f -
helm upgrade --install --create-namespace -n nginx-gateway -f nginx-gateway.values.yaml ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric
```

## Gateway

For deployment on HTTPS, prepare a certificate `nginx-gateway-tls` for TLS termination,
see https://docs.nginx.com/nginx-gateway-fabric/install/secure-certificates/ for further instructions.

Finally, deploy a `Gateway` using the NGINX fabric:

```bash
kubectl apply -f ./gateway.yaml
```

Or if you intend to use TLS passthrough:

```bash
kubectl apply -f ./gateway_tls_passthrough.yaml
```

## Examples

* [values.yaml](values.yaml) — Deploy and expose GraphDB over HTTP.
* [values_context_path.yaml](values_context_path.yaml) — Deploy GraphDB behind the context path `/graphdb`.
  The URL rewrite is applied automatically when a non-root context path is set in `externalUrl`.
* [values_https.yaml](values_https.yaml) — Deploy and expose GraphDB over HTTPS with TLS termination at the Gateway.
* [values_tls_passthrough.yaml](values_tls_passthrough.yaml) — Deploy GraphDB with TLS passthrough via a
  TLSRoute; GraphDB terminates TLS itself.
