# GraphDB Cluster in OpenShift

Example configurations for deploying GraphDB cluster in [OpenShift Local](https://developers.redhat.com/products/openshift-local/overview).

The primary purpose is to show an example of the necessary OpenShift local overrides and the proper `securityContext` configurations so 
GraphDB can be deployed without policy violations.

Read more about Kubernetes security context and OpenShift security context constraints:

- https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
- https://docs.openshift.com/container-platform/4.12/security/container_security/security-hosts-vms.html

## Usage

1. Create an OpenShift local instance

Follow the official [documentation](https://access.redhat.com/documentation/en-us/red_hat_openshift_local/2.15/html/getting_started_guide/installation_gsg)

Make sure you give the instance enough memory and CPU to be able to deploy the cluster. 
Or you can lower the memory and CPU requests/limits.

2. Create dedicated namespace

```bash
kubectl create namespace graphdb
```

3. To be able to deploy and use GraphDB in cluster mode, you have to create a secret with GraphDB license.

```bash
kubectl --namespace graphdb create secret generic graphdb-license --from-file graphdb.license=/path/to/graphdb.license
```

4. Deploy GraphDB

```bash
helm upgrade --install  --namespace graphdb --values values.yaml graphdb-openshift ../../
```

This will deploy a GraphDB cluster of 3 replicas along with a single GraphDB cluster proxy. 
Instances are configured for being accessed at [https://graphdb.apps-crc.testing](https://graphdb.apps-crc.testing).

5. Open a route to GraphDB's workbench

You'll have to use the `oc` utility provided by `crc` (from step 1):

```bash
oc create route edge --service=graphdb-cluster-proxy --port=7200 --hostname=graphdb.apps-crc.testing --namespace graphdb
```

You can now access GraphDB at [https://graphdb.apps-crc.testing/](https://graphdb.apps-crc.testing/).
