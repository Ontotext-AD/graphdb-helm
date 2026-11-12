# AWS Gateway API Examples

This folder contains examples of exposing GraphDB using the
[AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/) with Gateway API
support.

## Prerequisites

Install the Gateway API CRDs and the LB controller following the official documentation from
https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/guide/gateway/gateway/

The controller does not create a GatewayClass automatically — create one pointing at its controller:

```bash
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: alb
spec:
  controllerName: gateway.k8s.aws/alb
EOF
```

For HTTPS deployments, issue a certificate from AWS ACM https://aws.amazon.com/certificate-manager/.

## Gateway

Deploy a `LoadBalancerConfiguration` that will configure your Gateway to use HTTPS certificates from AWS ACM:

```bash
kubectl apply -f ./loadbalancerconfiguration.yaml
```

Finally, deploy a `Gateway` using the NGINX fabric:

```bash
kubectl apply -f ./gateway.yaml
```

## Examples

* [values.yaml](values.yaml) — Deploy and expose GraphDB over HTTP using an internet-facing ALB.
* [values_https.yaml](values_https.yaml) — Deploy and expose GraphDB over HTTPS with TLS termination at the ALB using an
  ACM certificate.

You should also deploy a `TargetGroupConfiguration` that will change the default target type to `ip` instead of
`instance`:

```bash
kubectl apply -f ./targetgroupconfiguration.yaml
```
