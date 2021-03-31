# Helm charts for GraphDB EE

## Install
### Prerequisites

#### Getting Started

If this is your first time installing a Helm chart, you should read the following introductions
before continuing:

- Docker https://docs.docker.com/get-started/
- Kubernetes concepts https://kubernetes.io/docs/concepts/
- Minikube https://kubernetes.io/docs/setup/learning-environment/minikube/
- Helm https://helm.sh/docs/intro/quickstart/

#### Binaries
- Install Helm 3: https://helm.sh/docs/intro/install/
- Install `kubectl`: https://kubernetes.io/docs/tasks/tools/install-kubectl/

**Note**: `sudo` may be required.

#### Kubernetes environment

##### Minikube

Follow the install documentation https://kubernetes.io/docs/setup/learning-environment/minikube/
for Minikube.

**Driver**

Carefully choose the suitable Minikube driver https://minikube.sigs.k8s.io/docs/drivers/ for
your system.

**Warning**: Some of them are compatible but have know issues. For example, the `docker` driver
does not support the ingress add-on which is required while the `none` driver goes into DNS
resolve loop in some Linux distributions.

**Resources**

It's important to define resource limitations for the Minikube environment. Otherwise it will
default to limits that may not be sufficient to deploy the whole chart.

The default resource limitations require around **12GB** of RAM. This is configurable per service in
[values.yaml](values.yaml) and should be tuned for every deployment.

When starting Minikube, it's preferable to define a bit more than the required amount.
For example, to create a Minikube environment in VirtualBox with 8 CPUs and 16GB of memory, use:

```bash
minikube start --vm-driver=virtualbox --cpus=8 --memory=16000
```

**Addons**

Minikube has built in services as part of its add-on system. By default, some of the required
plugins are disabled and have to be enabled.

To expose services, enable Minikube's ingress with:

```bash
minikube addons enable ingress
```

To collect metrics, enable Minikube's metrics server with:

```bash
minikube addons enable metrics-server
```

**DNS Resolving**

The chart is deployed with a Kubernetes ingress service that is configured to listen for requests
on a specific hostname. Any other requests are not handled.

This hostname is specified in [values.yaml](values.yaml) under `deployment.host`.
By default it configured for `localhost` which is suitable for the `none` Minikube driver.
In every other case you have to reconfigure it to a hostname that is DNS resolvable.

Some options are:

* Configure or update an existing DNS server - recommended for production deployment
* Update your hosts file - suitable for local development

To find out the IP address of the Minikube environment, use:

```bash
minikube ip
```

If you wish to access GraphDB locally on http://graphdb.local/ and the IP address of
the Minikube environment is `192.168.99.102` you should modify your hosts file with:

```
192.168.99.102  graphdb.local
```

See this how-to https://www.howtogeek.com/howto/27350/beginner-geek-how-to-edit-your-hosts-file/
about modifying the hosts file in different OS.

#### Secrets

After obtaining a GraphDB license from our sales team, create a secret with a `graphdb.license`
data entry:

```bash
kubectl create secret generic graphdb-license --from-file graphdb.license
```

**Note**: Secret names can differ from the given samples, but their configurations should be updated
to refer to the correct ones.

### Quick Start

The Helm chart includes an example repository configuration TTLs.

To install the GraphDB on `graphdb.local`:

```bash
helm install --set deployment.host=graphdb.local graphdb-ee .
```

After a few seconds, Helm will print out the result from installing GraphDB. 
You should see the following output:

```

--------------------------------------------------------------------------------------------
   ____                 _     ____  ____      _____ _____
  / ___|_ __ __ _ _ __ | |__ |  _ \| __ )    | ____| ____|
 | |  _| '__/ _` | '_ \| '_ \| | | |  _ \    |  _| |  _|
 | |_| | | | (_| | |_) | | | | |_| | |_) |   | |___| |___
  \____|_|  \__,_| .__/|_| |_|____/|____/    |_____|_____|
                 |_|
--------------------------------------------------------------------------------------------
version: 9.5.0
GDB cluster: true

** Please be patient while the chart is being deployed and services are available **
You can check their status with kubectl get pods

Endpoints:
* GraphDB workbench: http://graphdb.local/graphdb


```

## Persistence

By default, the Helm chart is deploying persistent volumes that stores data on the host path.
This is useful for local Minikube deployments. However, in a cloud environment with multiple node 
cluster this would lead to rescheduling and **data loss**.

See https://kubernetes.io/docs/concepts/storage/volumes/.

### Local deployment

Local persistent volumes are configured with `deployment.storage` from [values.yaml](values.yaml).

### Cloud deployment

For cloud deployment, you have to prepare persistent disks, storage class (or classes) and finally
persistent volumes manifests. Once this is done, every component must be reconfigured in 
[values.yaml](values.yaml) to point to the new persistent volume and not the default one. Each 
component has a section `persistence` that has to be updated.

## API Gateway

The services are proxied using Kong API gateway. By default, it is configured to route:

- GraphDB Workbench
- GraphDB Workbench workers if the cluster deployment is enabled

See the default declarative
[configuration](files/kong.dbless.yaml) of Kong to understand what and how is proxied.

To learn about the declarative syntax, see
https://docs.konghq.com/1.5.x/db-less-admin-api/#declarative-configuration.

## Customizing

Every component in configured with sensible defaults. Some of them are applied from
[values.yaml](values.yaml). Make sure you read it thoroughly, understand each property and the
impact of changing any one of them.

The properties are used across configuration maps and secrets and most of the components allow
the overriding of their configuration maps and secrets from [values.yaml](values.yaml).
See `<component>.configmap` and `<component>.secret`.

**Note**: If you are familiar with Kubernetes, you could modify the components configuration 
templates directly.

### values.yaml

Helm allows you to override values from [values.yaml](values.yaml) in several ways.
See https://helm.sh/docs/chart_template_guide/values_files/.

- Preparing another *values.yaml*:

```bash
helm install graphdb-ee . -f overrides.yaml
```

- Overriding specific values:

```bash
helm install graphdb-ee . --set monitoring.enabled=false --set security.enabled=false
```

### Deployment

Some of the important properties to update according to your deployment are:

* `deployment.protocol` and `deployment.host` - configure the ingress
controller and some of components on which they are accessible. The `deployment.host` must be a
resolvable hostname and not an IP address.
* `deployment.storage` configures components where to store their persistent data on the host system
running the Kubernetes environment.

### Resources

Each component is defined with default resource limits that are sufficient to deploy the chart
and use it with small sets of data. However, for production deployments it is obligatory to revise
these resource limits and tune them for your environment. You should consider common requirements
like amount of data, users, expected traffic.

Look for `<component>.resources` blocks in [values.yaml](values.yaml). During Helm's template 
rendering, these YAML blocks are inserted in the Kubernetes pod configurations as pod resource 
limits. Most resource configuration blocks are referring to official documentations.

See the Kubernetes documentation 
https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/
about defining resource limits.

### Node selectors

Each component in the Helm chart supports specifying a `nodeSelector` field in 
[values.yaml](values.yaml). This allows to schedule pods across a multi node cluster with different 
roles and resources. By default, no node restrictions are applied.

See https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/

### GraphDB repository

By default, the provisioning creates a default repository in GraphDB. This repo is provided by
`graphdb-repo-default-configmap` which reads it from
[worker.default.ttl](files/config/worker.default.ttl).

To change the default TTL, you can prepare another configuration map containing a
*config.ttl* file entry:

```bash
kubectl create configmap graphdb-repo-configmap --from-file=config.ttl
```

After that, update the property `graphdb.repositoryConfigmap` from
[values.yaml](values.yaml) to refer to the new configuration map.

### GraphDB cluster mode

The Helm chart allows to deploy GraphDB in cluster mode. By default this is disabled and only a single
master node is deployed. 

To deploy in cluster, set `graphdb.topology` in [values.yaml](values.yaml) to one of the following: 
1M_3W - 1 master with 3 or more workers cluster
2M3W_RW_RO - Two masters sharing 3 or more workers, one of the masters is read-only
2M3W_MUTED - Multiple masters with dedicated workers
See more about the cluster topologies here: https://graphdb.ontotext.com/documentation/enterprise/ee/cluster-topologies.html

Configure `graphdb.workersCount` to the desired replica amount. The 
`graphdb.workers` configurations are similar as to the master node. 

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| deployment.host | string | `"localhost"` | Important: This should be a resolvable hostname, not an IP address! |
| deployment.imagePullPolicy | string | `"IfNotPresent"` | Defines the policy with which components will request their image. |
| deployment.ingress | object | `{"maxRequestSize":"512M","timeout":{"connect":5,"read":60,"send":60}}` | Ingress related configurations |
| deployment.ingress.maxRequestSize | string | `"512M"` | Sets the maximum size for all requests to the underlying Nginx |
| deployment.ingress.timeout | object | `{"connect":5,"read":60,"send":60}` | Default timeouts in seconds for the underlying Nginx. |
| deployment.protocol | string | `"http"` | The hostname and protocol at which the graphdb will be accessible. Needed to configure ingress as well as some components require it to properly render their UIs |
| deployment.storage | string | `"/data"` | The storage place where components will read/write their persistent data in case the default persistent volumes are used. They use the node's file system. |
| deployment.tls | object | `{"enabled":false,"secretName":null}` | Configures SSL termination on ingress level. See https://kubernetes.github.io/ingress-nginx/examples/tls-termination/ |
| deployment.tls.enabled | bool | `false` | Feature toggle for SSL termination. Disabled by default. |
| deployment.tls.secretName | string | `nil` | Name of a Kubernetes secret object with the key and certificate. If TLS is enabled, it's required to be provided, depending on the deployment. |
| graphdb.arguments | string | `"-XX:MaxRAMPercentage=70 -XX:+UseContainerSupport"` | Extra arguments passed to GDB_JAVA_OPTS environment variable See http://graphdb.ontotext.com/documentation/enterprise/configuring-graphdb.html |
| graphdb.backupRestore.auto_backup | string | `"* 0 * * *"` | Cron Schedule for auto backup |
| graphdb.backupRestore.backup_max_age | string | `"5"` | Max number of days for backups |
| graphdb.backupRestore.backups_count | string | `"5"` | Max number of backups allowed |
| graphdb.backupRestore.cleanup_cron | string | `"* 1 * * *"` | Cron Schedule for cleanup |
| graphdb.backupRestore.restore_from_backup | string | `"03-30-2021-07-16"` | The name of the backup to restore |
| graphdb.backupRestore.trigger_backup | string | `"30.03.2021 07:16"` | The date at which a backup should be triggered. Must be given in format DD.MM.YYYY hh:mm |
| graphdb.backupRestore.trigger_restore | string | `"30.03.2021 07:21"` | The date at which a restore should be triggered. Must be given in format DD.MM.YY hh:mm. Not used for standalone. In standalone a restore is triggered every time a container is initialized |
| graphdb.clusterConfig.masterWorkerMapping | list | `["master-1 -> worker-1","master-1 -> worker-2","master-2 -> worker-3","master-2 -> worker-4"]` | used only for 2m3w_muted |
| graphdb.clusterConfig.mutedMasters | list | `["master-2"]` | used only for 2m3w_muted |
| graphdb.clusterConfig.readOnlyMasters | list | `["master-2"]` | used only for 2m3w_rw_ro |
| graphdb.clusterConfig.syncPeersMapping | list | `["master-1 <-> master-2"]` | used only for 2m3w_rw_ro, 2m3w_muted |
| graphdb.clusterSecret | string | `"s3cr37"` | A secret used for secure communication amongst the nodes in the cluster. Reference to a secret containing 'graphdb.license' file. This is a required secret without which GraphDB won't operate if you use anything than the free edition. Important: Must be created beforehand |
| graphdb.masters.java_args | string | `" -Xmx4G -XX:MaxRAMPercentage=70 -XX:+UseContainerSupport"` |  |
| graphdb.masters.license | string | `"graphdb-masters-license"` |  |
| graphdb.masters.nodeSelector | object | `{}` |  |
| graphdb.masters.nodes[0] | object | `{"name":"master-1"}` | Schedule and assign on specific node. By default, no restrictions are applied. See https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/ |
| graphdb.masters.persistence.storage | string | `"10G"` | Storage size request. The persistent volume has to be able to satisfy the size. |
| graphdb.masters.persistence.storageClassName | string | `"standard"` |  |
| graphdb.masters.persistence.volumeNamePrefix | string | `"graphdb-master-default"` | Name reference of a persistent volume to which the claim will try to attach. |
| graphdb.masters.repository | string | `"test"` | The repository used by the semantic objects service. This repo will be initialized during of Helm's post install hooks. See hooks/post-install/10-graphdb-provision-repo.yaml |
| graphdb.masters.repositoryConfigmap | string | `"graphdb-repo-default-configmap"` | Reference to a configuration map containing a repository 'config.ttl' file used for initialization in the post install hook. Not required if hooks are skipped in favor of clean installation. |
| graphdb.masters.resources | object | `{"limits":{"memory":"4Gi"},"requests":{"memory":"2Gi"}}` | Below are minimum requirements for data sets of up to 50 million RDF triples For resizing, refer according to your GraphDB version documentation For EE see http://graphdb.ontotext.com/documentation/enterprise/requirements.html |
| graphdb.mastersCount | int | `2` |  |
| graphdb.nodeSelector | object | `{}` | Schedule and assign on specific node. By default, no restrictions are applied. See https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/ |
| graphdb.topology | string | `"2m3w_rw_ro"` |  |
| graphdb.workbench.subpath | string | `"/graphdb"` | This is the sub path at which GraphDB workbench can be opened. Should be configured in the API gateway (or any other proxy in front) |
| graphdb.workers.java_args | string | `" -Xmx2G -XX:MaxRAMPercentage=70 -XX:+UseContainerSupport"` |  |
| graphdb.workers.license | string | `"graphdb-workers-license"` |  |
| graphdb.workers.nodeSelector | object | `{}` | Schedule and assign on specific node. By default, no restrictions are applied. See https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/ |
| graphdb.workers.nodes[0].license | string | `"graphdb-worker1-license"` |  |
| graphdb.workers.nodes[0].master | string | `"master-1"` |  |
| graphdb.workers.nodes[0].name | string | `"worker-1"` |  |
| graphdb.workers.nodes[1].java_args | string | `" -Xmx1G -XX:MaxRAMPercentage=70 -XX:+UseContainerSupport"` |  |
| graphdb.workers.nodes[1].name | string | `"worker-2"` |  |
| graphdb.workers.persistence.repositoryConfigmap | string | `"graphdb-worker-repo-default-configmap"` | Reference to a configuration map containing a worker node repository 'config.ttl' file used for initialization in the post install hook. |
| graphdb.workers.persistence.storage | string | `"10G"` | Storage size request. The persistent volume has to be able to satisfy the size. |
| graphdb.workers.persistence.storageClassName | string | `"standard"` |  |
| graphdb.workers.persistence.volumeNamePrefix | string | `"graphdb-worker-default"` | Name reference prefix of a persistent volume to which the claim will try to attach. Example result: graphdb-worker-default-worker-1-pv |
| graphdb.workers.repository | string | `"test"` |  |
| graphdb.workers.repositoryConfigmap | string | `"graphdb-worker-repo-default-configmap"` |  |
| graphdb.workers.resources | object | `{"limits":{"memory":"4Gi"},"requests":{"memory":"2Gi"}}` | Below are minimum requirements for data sets of up to 50 million RDF triples For resizing, refer according to your GraphDB version documentation For EE see http://graphdb.ontotext.com/documentation/enterprise/requirements.html Note: Same as for the master node |
| graphdb.workersCount | int | `4` |  |
| images | object | `{"alpine":"ontotext/graphdb:9.5.0-ee","busybox":"busybox:1.31","graphdb":"ontotext/graphdb:9.5.0-ee","kong":"kong:2.1-alpine"}` | Top lvl flat for easier maintenance |
| kong.configmap | string | `"kong-configmap"` | Reference to a configuration map with Kong configurations as environment variables. Override if you need to further configure Kong's system. See https://docs.konghq.com/2.0.x/configuration/ |
| kong.memCacheSize | string | `"64m"` | Memory cache size configuration for Kong in DB-less mode. Tune according to the given resource limits. See https://docs.konghq.com/2.0.x/configuration/#mem_cache_size |
| kong.nodeSelector | object | `{}` | Schedule and assign on specific node. By default, no restrictions are applied. See https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/ |
| kong.port | object | `{"nodePort":31122}` | Overwrite if you want to deploy Kong on a non-standard port, such as instances where you want to have two different installations on the same hardware. |
| kong.resources | object | `{"limits":{"memory":"2048Mi"}}` | Default resource limitations. |
| kong.servicesConfigmap | string | `"kong-services-configmap"` | Reference to a configuration map containing declarative Kong configuration for services and routes. This is the DB-less config. See https://docs.konghq.com/1.5.x/db-less-admin-api/#declarative-configuration |
| kong.timeout | object | `{"connect":60000,"read":60000,"write":60000}` | Global timeout configurations for all services. Values are in milliseconds. |
| kong.workers | string | `"auto"` | Amount of Nginx worker processes. This affects how much memory will be consumed. The auto value will determine the workers based on the available CPUs |
| versions.api | string | `"apps/v1"` |  |
| versions.configmap | string | `"v1"` |  |
| versions.daemon | string | `"apps/v1"` |  |
| versions.deployment | string | `"apps/v1"` |  |
| versions.ingress | string | `"extensions/v1beta1"` |  |
| versions.job | string | `"batch/v1"` |  |
| versions.pv | string | `"v1"` |  |
| versions.pvc | string | `"v1"` |  |
| versions.secret | string | `"v1"` |  |
| versions.service | string | `"v1"` |  |
| versions.volume | string | `"v1"` |  |

----------------------------------------------

## Uninstall
To remove the deployed GraphDB, use:

```bash
helm uninstall graphdb-ee
```

**Note**: It is important to note that this will not remove any data, so the next time it 
is installed, the data will be loaded by its components.

Provisioning will be skipped also.

## Troubleshoot

**Helm install hangs**

If there is no output after `helm install`, it is likely that a hook cannot execute.
Check the logs with `kubectl logs`.

**Connection issues**

If connections time out or the pods cannot resolve each other, it is likely that the Kubernetes
DNS is broken. This is a common issue with Minikube between system restarts or when inappropriate 
Minikube driver is used. Please refer to 
https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/.
