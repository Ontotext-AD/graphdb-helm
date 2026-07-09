# AWS Gateway API Examples

This folder contains examples of exposing GraphDB using the
[AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/) with Gateway API support.

## Prerequisites

Install the Gateway API CRDs (v1.2.0+ required — earlier versions don't have the `spec.infrastructure`
field used by `gatewayApi.gateway.infrastructure`):

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
```

AWS Load Balancer Controller v2.13+ (Gateway API support requires v2.13+), with the `ALBGatewayAPI`
feature gate enabled:

```bash
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=<your-cluster-name> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set featureGates.ALBGatewayAPI=true
```

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

## Examples

* [values.yaml](values.yaml) + [loadbalancerconfiguration.yaml](loadbalancerconfiguration.yaml) —
  Deploy and expose GraphDB over HTTP using an internet-facing ALB.
* [values_https.yaml](values_https.yaml) + [loadbalancerconfiguration_https.yaml](loadbalancerconfiguration_https.yaml) —
  Deploy and expose GraphDB over HTTPS with TLS termination at the ALB using an ACM certificate.
* [values_cluster.yaml](values_cluster.yaml) + [loadbalancerconfiguration_cluster.yaml](loadbalancerconfiguration_cluster.yaml) —
  Deploy a GraphDB cluster and expose its gRPC inter-node port externally via a GRPCRoute. Requires a
  GraphDB Enterprise Edition license and an ACM certificate (the gRPC listener must terminate TLS on
  AWS - see the note in values_cluster.yaml).
