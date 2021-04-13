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

To enable Minikube's monitoring dashboard with:

```bash
minikube dashboard
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

**Note**: Secret names can differ from the given examples in the [values.yaml](values.yaml), but their configurations should be updated
to refer to the correct ones. Note that the licenses can be set for all masters/workers instances and also per instance. Please setup correctly according to the licensing agreements.

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
version: 9.7.0
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

### Customizing GraphDB cluster and GraphDB specific properties

GraphDB's Helm chart is made to be highly customizable regarding GraphDB's specific options and properties. 
There are 3 important configuration sections:
- GraphDB cluster configuration
- Cluster instances (masters/workers) configuration
- Backup, restore and cleanup options

#### GraphDB cluster configuration

By default the Helm chart supports the 3 topologies that we recommend in our documentation. This is configured by settings `graphdb.topology`
Possible values: `standalone, 1m_3w, 2m3w_rw_ro, 2m3w_muted`. Masters and workers count in cluster modes are controlled by mastersCount and workersCount properties

**standalone** - Launches single instance of GraphDB with a preconfigured worker repository. 

**1m_3w** - 1 master and multiple workers. https://graphdb.ontotext.com/documentation/enterprise/ee/setting-up-a-cluster-with-one-master.html

**2m3w_rw_ro** - 2 masters, one of which is read only and multiple workers. https://graphdb.ontotext.com/documentation/enterprise/ee/setting-up-a-cluster-with-a-second-readonly-master.html

**2m3w_muted** - 2 masters, one of which is muted and multiple workers. https://graphdb.ontotext.com/documentation/enterprise/ee/setting-up-a-cluster-with-multiple-masters-with-dedicated-workers.html

Note: If "standalone" is selected, the launched instance will use master-1 properties, but a worker repository will be created!

- The section `graphdb.clusterConfig` can be used to configure a GraphDB cluster. It's responsible for the connections between the cluster instances and their settings (muted, readonly).
- The subsection `graphdb.clusterConfig.masterWorkerMapping` describes which GraphDB instances will be linked. The format must be `master-X -> worker-Y`. Required only for `2m3w_muted` topology.
- The subsection `graphdb.clusterConfig.readOnlyMasters` describes which GraphDB master instances will be set as read only. The format must be `master-X`. Required only for `2m3w_rw_ro` topology.
- The subsection `graphdb.clusterConfig.mutedMasters` describes  which GraphDB master instances will be linked as sync peer. The format must be `master-X <-> master-Y`. Required for `2m3w_rw_ro` and `2m3w_muted` topology.

`graphdb.clusterConfig.workersCount` and `graphdb.clusterConfig.mastersCount` tell the chart how many worker instances and how many masters instances to be launched.

See more about the cluster topologies here: https://graphdb.ontotext.com/documentation/enterprise/ee/cluster-topologies.html

#### Cluster instances (masters/workers) configuration

GraphDB's Helm chart allows some configurations to be set for all masters or all workers instances. It also allows overrides of some configurations for each worker instance or each master instance.
The global configurations for all masters/workers instances are placed in the section `graphdb.masters.*` and `graphdb.workers.*`. 

Each configuration can be overridden for each master/worker node. The overrides are described in `graphdb.masters.nodes.*` and `graphdb.workers.nodes.*`. In those subsections specific configurations for each cluster node can be specified in the format:

```bash
nodes:
    - name: master-1
        java_args: " -Xmx4G -XX:MaxRAMPercentage=70 -XX:+UseContainerSupport"
        nodeSelector: {}
        license: graphdb-license
```

For now the supported configurations are `java_args`, `node_selector` and `license`

For more information about node selectors see https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/

#### Backup, restore and cleanup options

GraphDB's Helm chart supports automatic backup, restore and cleanup procedures. There are a few options that are used to describe the required jobs that handle those tasks.

Those options are described in the subsection `graphdb.backupRestore.*` and they are:
- auto_backup - cron Schedule for auto backup. Creates an automatic backup, stored in the backup-pv (default folder - /data/graphdb-backups). The backups are saved in format MM-DD-YYYY-hh-mm
- cleanup_cron - cleans up the backups directory. Makes sure that there is a limit of the stored backups. Each or both of `backups_count` and `backups_max_age` could be used.
- backups_count - max number of backup dirs saved.
- backup_max_age - max number of days for backups.
- trigger_backup - a future date at which we want to trigger a backup. Must be given in format DD.MM.YYYY hh:mm. Please bear in mind that there could be a time difference with the kubernetes environment
- trigger_restore - a future date at which we want to trigger a restore. Works only with a cluster with workers. For a standalone the restore is called from an init container. Must be given in format DD.MM.YYYY hh:mm
- restore_from_backup - the name of the backup directory we want to restore. Must be given in format MM-DD-YY-hh-mm, where MM-DD-YY-hh-mm is your backup directory

#### Preload, LoadRDF, Storage tools
GraphDB's Helm chart supports preload and LoadRDF tools for preloading data. It also supports Storage tool for scanning and repairing data. There are a few options that are used to run the needed commands.

Those options are described in the subsection `graphdb.tools.*` and they are:

- resources - to set the needed resources in order to run the tools. Bear in mind that if you don't give the init containers enough resources, the tools might fail. 
```bash
resources:
  limits:
    cpu: 4
    memory: "10Gi"
  requests:
    cpu: 4
    memory: "10Gi"
```
- preload - tool to preload data in a chosen repository.
  - trigger - If trigger is set to true, then the preload tool will be run while initializing the deployment.
  - flags - options to add to the command. The possible options are "-f", "-p", "-r". If you use the "-f" option, the tool will override the repository and could lose some data.
  - rdfDataFile - the file that is added in the mounted directory.

For more information about the Preload tool see: https://graphdb.ontotext.com/documentation/enterprise/loading-data-using-preload.html

- loadrdf - tool to preload data in a chosen repository.
  - trigger - if trigger is set to true, then the loadrdf tool will be run while initializing the deployment.
  - flags - options to add to the command. The possible options are "-f", "-p". If you use the "-f" option, the tool will override the repository and could lose some data. 
  - rdfDataFile - the file that is added in the mounted directory.

For more information about the LoadRDF tool see: https://graphdb.ontotext.com/documentation/enterprise/loading-data-using-the-loadrdf-tool.html

- storage_tool - tool for scanning and repairing data.
  - trigger - if trigger is set to true, then the storage tool will be run while initializing the deployment.
  - command - the command to run the storage-tool with.
  - repository - repo to run command on.
  - options - additional options to run the storage-tool with. 

For more information about the Storage tool see https://graphdb.ontotext.com/documentation/enterprise/storage-tool.html

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

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| deployment.host | string | `"localhost"` |  |
| deployment.imagePullPolicy | string | `"IfNotPresent"` | Defines the policy with which components will request their image. |
| deployment.ingress | object | `{"maxRequestSize":"512M","timeout":{"connect":5,"read":60,"send":60}}` | Ingress related configurations |
| deployment.ingress.maxRequestSize | string | `"512M"` | Sets the maximum size for all requests to the underlying Nginx |
| deployment.ingress.timeout | object | `{"connect":5,"read":60,"send":60}` | Default timeouts in seconds for the underlying Nginx. |
| deployment.protocol | string | `"http"` | The hostname and protocol at which the graphdb will be accessible. Needed to configure ingress as well as some components require it to properly render their UIs |
| deployment.storage | string | `"/data"` | The storage place where components will read/write their persistent data in case the default persistent volumes are used. They use the node's file system. |
| deployment.tls.enabled | bool | `false` | Feature toggle for SSL termination. Disabled by default. |
| deployment.tls.secretName | string | `nil` | Name of a Kubernetes secret object with the key and certificate. If TLS is enabled, it's required to be provided, depending on the deployment. |
| graphdb.tools | object | `{"loadrdf":{"flags":"-f","rdfDataFile":"geonames_europe.ttl ","trigger":false},"preload":{"flags":"-f","rdfDataFile":"geonames_europe.ttl ","trigger":true},"storage_tool":{"command":"scan","options":"","repository":"repo-test-1","trigger":false}}` | Tools for loading, scanning and repairing data in repos |
| graphdb.tools.loadrdf | object | `{"flags":"-f","rdfDataFile":"geonames_europe.ttl ","trigger":false}` | Tool to preload data in a chosen repo https://graphdb.ontotext.com/documentation/enterprise/loading-data-using-the-loadrdf-tool.html |
| graphdb.tools.loadrdf.flags | string | `"-f"` | Options to add to the command possible flags: -f, -p |
| graphdb.tools.loadrdf.trigger | bool | `false` | If trigger is set to true, then the loadrdf tool will be run while initializing the deployment Don't forget to add repo config file(should be named config.ttl) and RDF data file to the graphdb-preload-data-pv (default pv is: /data/graphdb-worker-preload-data) |
| graphdb.tools.preload | object | `{"flags":"-f","rdfDataFile":"geonames_europe.ttl ","trigger":true}` | Tool to preload data in a chosen repo https://graphdb.ontotext.com/documentation/enterprise/loading-data-using-preload.html |
| graphdb.tools.preload.flags | string | `"-f"` | Options to add to the command possible flags: -f, -p, -r |
| graphdb.tools.preload.trigger | bool | `true` | If trigger is set to true, then the preload tool will be run while initializing the deployment Don't forget to add repo config file(should be named config.ttl) and RDF data file to the graphdb-preload-data-pv (default pv is: /data/graphdb-worker-preload-data) |
| graphdb.tools.storage_tool | object | `{"command":"scan","options":"","repository":"repo-test-1","trigger":false}` | Tool for scanning and repairing data See https://graphdb.ontotext.com/documentation/enterprise/storage-tool.html |
| graphdb.tools.storage_tool.command | string | `"scan"` | commands to run the storage-tool with |
| graphdb.tools.storage_tool.options | string | `""` | additional options to run the storage-tool with if you want to use the option rebuild with -srcIndex=pso -destIndex=pso or -srcIndex=pso -destIndex=pos, don't forget to make the workers' memory limits 10Gi |
| graphdb.tools.storage_tool.repository | string | `"repo-test-1"` | repo to run command on |
| graphdb.tools.storage_tool.trigger | bool | `false` | If trigger is set to true, then the storage tool will be run while initializing the deployment |
| graphdb.backupRestore.auto_backup | string | `"* 0 * * *"` | Cron Schedule for auto backup. Creates an automatic backup, stored in the backup-pv (default folder - /data/graphdb-backups). The backups are saved in format MM-DD-YYYY-hh-mm TODO: Add PV options for backups |
| graphdb.backupRestore.backup_max_age | string | `"5"` | Max number of days for backups. |
| graphdb.backupRestore.backups_count | string | `"5"` | Max number of backup dirs saved. |
| graphdb.backupRestore.cleanup_cron | string | `"* 1 * * *"` | Cleans up the backups directory. Makes sure that there is a limit of the stored backups. Each or both of backups_count and backups_max_age could be used. |
| graphdb.backupRestore.restore_from_backup | string | `"03-31-2021-14-47"` | The name of the backup directory we want to restore. Must be given in format MM-DD-YY-hh-mm, where MM-DD-YY-hh-mm is your backup directory |
| graphdb.backupRestore.trigger_restore | string | `"31.03.2021 14:50"` |  |
| graphdb.clusterConfig.clusterSecret | string | `"s3cr37"` |  |
| graphdb.clusterConfig.masterWorkerMapping | list | `["master-1 -> worker-1","master-1 -> worker-2","master-2 -> worker-3","master-2 -> worker-4"]` | Describes how the masters and workers are linked in the format master-X -> worker-Y. Required only for 2m3w_muted topology. |
| graphdb.clusterConfig.mastersCount | int | `2` |  |
| graphdb.clusterConfig.mutedMasters | list | `["master-2"]` | Describes which masters will be set as muted. Required only for 2m3w_muted topology. |
| graphdb.clusterConfig.readOnlyMasters | list | `["master-2"]` | Describes which masters will be set as read only. Required only for 2m3w_rw_ro topology. |
| graphdb.clusterConfig.syncPeersMapping | list | `["master-1 <-> master-2"]` | Describes which masters will be linked as sync peer. Required for 2m3w_rw_ro and 2m3w_muted topology. |
| graphdb.clusterConfig.workersCount | int | `4` |  |
| graphdb.masters.java_args | string | `" -Xmx4G -XX:MaxRAMPercentage=70 -XX:+UseContainerSupport"` | Java arguments with which master instances will be launched. GraphDB configuration properties can also be passed here in the format -Dprop=value |
| graphdb.masters.license | string | `"graphdb-license"` | Reference to a secret containing 'graphdb.license' file to be used by master nodes. This is a required secret without which GraphDB won't operate if you use SE/EE editions. Important: Must be created beforehand |
| graphdb.masters.nodeSelector | object | `{}` | Schedule and assign on specific node for ALL masters. By default, no restrictions are applied. This can be specified per instance in the nodes section. See https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/ |
| graphdb.masters.nodes | list | `[{"java_args":" -Xmx4G -XX:MaxRAMPercentage=70 -XX:+UseContainerSupport","license":"graphdb-license","name":"master-1","nodeSelector":{}}]` | Specific GraphDB master instances configurations. Supported properties for per node configuration are: license, java_args, graphdb_properties |
| graphdb.masters.persistence | object | `{"storage":"10G","storageClassName":"standard","volumeNamePrefix":"graphdb-master-default"}` | Persistence configurations. By default, Helm will use a PV that reads and writes to the host file system. |
| graphdb.masters.persistence.storage | string | `"10G"` | Storage size request for each master. The persistent volume has to be able to satisfy the size. |
| graphdb.masters.persistence.volumeNamePrefix | string | `"graphdb-master-default"` | Name reference of a persistent volume to which the claim will try to attach. Example result: graphdb-master-default-worker-1-pv |
| graphdb.masters.repository | string | `"test"` | The repository name to be created for all masters. This repository will be initialized during of Helm's post install hooks. |
| graphdb.masters.repositoryConfigmap | string | `"graphdb-repo-default-configmap"` | Reference to a configuration map containing a repository 'config.ttl' file used for repository initialization in the post install hook. For reference see https://graphdb.ontotext.com/documentation/standard/configuring-a-repository.html |
| graphdb.masters.resources | object | `{"limits":{"memory":"4Gi"},"requests":{"memory":"2Gi"}}` | Below are minimum requirements for data sets of up to 50 million RDF triples For resizing, refer according to your GraphDB version documentation For EE see http://graphdb.ontotext.com/documentation/enterprise/requirements.html |
| graphdb.topology | string | `"2m3w_rw_ro"` | Cluster topology to be used. Possible values: standalone, 1m_3w, 2m3w_rw_ro, 2m3w_muted. standalone - Launches single instance of GraphDB with a preconfigured worker repository. Masters and workers count is controlled by mastersCount and workersCount properties 1m_3w - 1 master and multiple workers. https://graphdb.ontotext.com/documentation/enterprise/ee/setting-up-a-cluster-with-one-master.html 2m3w_rw_ro - 2 masters, one of which is read only and multiple workers. https://graphdb.ontotext.com/documentation/enterprise/ee/setting-up-a-cluster-with-a-second-readonly-master.html 2m3w_muted - 2 masters, one of which is muted and multiple workers. https://graphdb.ontotext.com/documentation/enterprise/ee/setting-up-a-cluster-with-multiple-masters-with-dedicated-workers.html Note: If "standalone" is selected, the launched instance will use master-1 properties, but a worker repository will be created! |
| graphdb.workbench.subpath | string | `"/graphdb"` | This is the sub path at which GraphDB workbench can be opened. Should be configured in the API gateway (or any other proxy in front) |
| graphdb.workers.java_args | string | `" -Xmx2G -XX:MaxRAMPercentage=70 -XX:+UseContainerSupport"` | Java arguments with which worker instances will be launched. GraphDB configuration properties can also be passed here in the format -Dprop=value |
| graphdb.workers.license | string | `"graphdb-license"` | Reference to a secret containing 'graphdb.license' file to be used by worker nodes. This is a required secret without which GraphDB won't operate if you use SE/EE editions. Important: Must be created beforehand |
| graphdb.workers.nodeSelector | object | `{}` | Schedule and assign on specific node for ALL workers. By default, no restrictions are applied. This can be specified per instance in the nodes section. See https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/ |
| graphdb.workers.nodes | list | `[{"license":"graphdb-license","name":"worker-1"},{"java_args":" -Xmx1G -XX:MaxRAMPercentage=70 -XX:+UseContainerSupport","name":"worker-2","nodeSelector":{}}]` | Specific GraphDB worker instances configurations. Supported properties for per node configuration are: license, java_args, graphdb_properties |
| graphdb.workers.persistence | object | `{"repositoryConfigmap":"graphdb-worker-repo-default-configmap","storage":"10G","storageClassName":"standard","volumeNamePrefix":"graphdb-worker-default"}` | Persistence configurations. By default, Helm will use a PV that reads and writes to the host file system. |
| graphdb.workers.persistence.repositoryConfigmap | string | `"graphdb-worker-repo-default-configmap"` | Reference to a configuration map containing a worker node repository 'config.ttl' file used for initialization in the post install hook. |
| graphdb.workers.persistence.storage | string | `"10G"` | Storage size request for each worker. The persistent volume has to be able to satisfy the size. |
| graphdb.workers.persistence.volumeNamePrefix | string | `"graphdb-worker-default"` | Name reference prefix of a persistent volume to which the claim will try to attach. Example result: graphdb-worker-default-worker-1-pv |
| graphdb.workers.repository | string | `"test"` | The repository name to be created for all workers. This repository will be initialized during of Helm's post install hooks. |
| graphdb.workers.repositoryConfigmap | string | `"graphdb-worker-repo-default-configmap"` | Reference to a configuration map containing a repository 'config.ttl' file used for repository initialization in the post install hook. For reference see https://graphdb.ontotext.com/documentation/standard/configuring-a-repository.html |
| graphdb.workers.resources | object | `{"limits":{"memory":"4Gi"},"requests":{"memory":"2Gi"}}` | Below are minimum requirements for data sets of up to 50 million RDF triples For resizing, refer according to your GraphDB version documentation For EE see http://graphdb.ontotext.com/documentation/enterprise/requirements.html Note: Same as for the master node |
| images.alpine | string | `"docker-registry.ontotext.com/graphdb-ee:9.8.0-HOSTS-TR3-adoptopenjdk11"` |  |
| images.busybox | string | `"busybox:1.31"` |  |
| images.graphdb | string | `"docker-registry.ontotext.com/graphdb-ee:9.8.0-HOSTS-TR3-adoptopenjdk11"` |  |
| images.kong | string | `"kong:2.1-alpine"` |  |
| kong.configmap | string | `"kong-configmap"` | Reference to a configuration map with Kong configurations as environment variables. Override if you need to further configure Kong's system. See https://docs.konghq.com/2.0.x/configuration/ |
| kong.memCacheSize | string | `"64m"` | Memory cache size configuration for Kong in DB-less mode. Tune according to the given resource limits. See https://docs.konghq.com/2.0.x/configuration/#mem_cache_size |
| kong.nodeSelector | object | `{}` |  |
| kong.port | object | `{"nodePort":31122}` | Overwrite if you want to deploy Kong on a non-standard port, such as instances where you want to have two different installations on the same hardware. |
| kong.resources.limits.memory | string | `"2048Mi"` |  |
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
Autogenerated from chart metadata using [helm-docs v1.5.0](https://github.com/norwoodj/helm-docs/releases/v1.5.0)

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
