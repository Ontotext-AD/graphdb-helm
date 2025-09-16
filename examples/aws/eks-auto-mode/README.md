# Deploying GraphDB on EKS Auto Mode

## Prerequisites

* EKS Auto Mode Cluster: Ensure you have an [Amazon EKS cluster with Auto Mode enabled](https://docs.aws.amazon.com/eks/latest/userguide/create-auto.html).
* GP3 Storage Class: You must [create a StorageClass](https://docs.aws.amazon.com/eks/latest/userguide/create-storage-class.html) that uses the EKS specific provisioner.
* Configure [IngressClass](https://docs.aws.amazon.com/eks/latest/userguide/auto-configure-alb.html) in order to set up Ingress.
* Configure custom [EKS NodePool](https://docs.aws.amazon.com/eks/latest/userguide/create-node-pool.html) tuned to your requirements.

## Configuration

### Configuring Storage Class

After you create you StorageClass that uses EKS Auto Mode as provisioner, you must reference it in the values.yaml
file so your GraphDB and Graphdb proxy instances use it:

```yaml
persistence:
  volumeClaimTemplate:
    spec:
      storageClassName: auto-ebs-sc
proxy:
  persistence:
    volumeClaimTemplate:
      spec:
        storageClassName: auto-ebs-sc
```

### Configuring Ingress

The annotations and extra properties when configuring Ingress in EKS Auto mode should be specified in IngressClassParams:

```yaml
apiVersion: eks.amazonaws.com/v1
kind: IngressClassParams
metadata:
  name: alb
spec:
  scheme: internet-facing
  certificateARNs: # When using SSL
    - arn:aws:acm:region:account:certificate/id
```

Then, configure your Ingress to use the IngressClass that is referencing the created IngressClassParams.

```yaml
configuration:
  # Change this to your Route53 domain name or use nip.io which you can do after you deploy the chart since you
  # need to map the public IP address of the AWS Load Balancer to the nip.io.
  externalUrl: http://ip.address.nip.io/

ingress:
  enabled: true
  className: alb
```

### Configuring Network Load Balancer

Example of how to deploy and expose GraphDB with [Network Load Balancer](https://docs.aws.amazon.com/eks/latest/userguide/auto-configure-nlb.html) without SSL enabled:

```yaml
service:
  enabled: true
  ports:
   http: 80
  type: LoadBalancer
  loadBalancerClass: "eks.amazonaws.com/nlb"
  loadBalancerSourceRanges: ["0.0.0.0/0"]
  annotations:
   service.beta.kubernetes.io/aws-load-balancer-name: "graphdb-lb"
   service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
    # This ensures the load balancer is public
   service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
   service.beta.kubernetes.io/aws-load-balancer-attributes: "load_balancing.cross_zone.enabled=true"
```

Example of how to deploy and expose GraphDB with Network Load Balancer with SSL enabled:

```yaml
service:
  enabled: true
  ports:
    http: 443
  type: LoadBalancer
  loadBalancerClass: "eks.amazonaws.com/nlb"
  loadBalancerSourceRanges: ["0.0.0.0/0"]
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-name: "graphdb-lb"
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
    # This ensures the load balancer is public
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
    # ARN of the ACM SSL Certificate that will be used
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: ""
    service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "443"
    service.beta.kubernetes.io/aws-load-balancer-ssl-negotiation-policy: "ELBSecurityPolicy-TLS13-1-2-2021-06"
    service.beta.kubernetes.io/aws-load-balancer-attributes: "load_balancing.cross_zone.enabled=true"
```

### Configuring custom NodePool

The nodes provisioned automatically by Karpenter may use arbitrary instance types, which can lead to issues such as:

  - Different CPU architectures or virtualization types across nodes
  - Varying CPU counts with the same memory size, resulting in inconsistent performance
  - Other unpredictable hardware differences

To avoid this, you can restrict provisioning to a specific instance family and CPU architecture by using a node selector.

This is typically done by creating a [Node Pool](https://docs.aws.amazon.com/eks/latest/userguide/create-node-pool.html) with the desired constraints, and then
configuring the GraphDB and Proxy pods to schedule only onto nodes provisioned from that custom pool.

```yaml
nodeSelector:
  karpenter.sh/nodepool: my-node-pool
proxy:
  nodeSelector:
    karpenter.sh/nodepool: my-node-pool
```

### Spreading pods across different nodes

To ensure that pods are scheduled on different nodes and that GraphDB and GraphDB Proxy pods do not run on the same
node, you need to configure additional podAntiAffinity rules, for example:

```yaml
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      # One graphdb pod per node
      - topologyKey: kubernetes.io/hostname
        labelSelector:
          matchExpressions:
            - key: app.kubernetes.io/name
              operator: In
              values:
                - "graphdb"
                - "graphdb-proxy"
```

You should also configure the same podAntiAffinity rules to prevent GraphDB Proxy pods from
being scheduled on the same nodes as GraphDB pods:

```yaml
proxy:
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        # One graphdb-proxy pod per node
        - topologyKey: kubernetes.io/hostname
          labelSelector:
            matchExpressions:
              - key: app.kubernetes.io/name
                operator: In
                values:
                  - "graphdb"
                  - "graphdb-proxy"
```

### Karpenter node-rebalancing

To ensure that Karpenter’s node rebalancing does not disrupt the workload, you should configure PodDisruptionBudgets.
The PDB is set by default to 51%, which guarantees that more than half of the pods remain available and thus maintains cluster quorum during evictions.
