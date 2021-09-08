# Helm charts for GraphDB EE

## WARNING

This is a basic experimental Helm chart for GraphDB. We're working on some features that are missing at the moment such as:

- Autoscaling

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
version: 9.8.0
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


### GraphDB repositories

By default, the provisioning creates a default repository in GraphDB. This repo is provided by
`graphdb-master-repo-default-configmap` for master instances and `graphdb-worker-repo-default-configmap` for worker instances.
The repositories are created using .ttl repository configuration files, by default those are [worker.default.ttl](files/config/worker.default.ttl) and [master.default.ttl](files/config/master.default.ttl).

Provisioning of multiple repositories is also supported. If the configmaps contain more than one .ttl file, the provisioning will create the repositories from all .ttl files contained in the configmap.
Note that `master` and `worker` repositories are different and must be supplied correctly in a cluster environment.
Also note that when standalone GraphDB instance is used, the master configmap is used, but with a `worker` `config.ttl`!

To change the default TTL, you can prepare another configuration map containing a
`config.ttl` file(s)  entry:

```bash
kubectl create configmap graphdb-repo-configmap --from-file=config.ttl
```

After that, update the property `graphdb.masters.repositoryConfigmap` / `graphdb.workers.repositoryConfigmap` from
[values.yaml](values.yaml) to refer to the new configuration map.

#### Ontop repositories

Ontop repositories require a jdbc driver. To use this type of repository, you have to provide a jdbc driver named `jdbc-driver.jar`.
It must be located in each GraphDB instance in which you wish to use with Ontop repository, in the folder `/opt/graphdb/home/jdbc-driver`.
The directory is part of the GraphDB home directory which is persistent, so the driver will persist after a restart or reschedule of a GraphDB pod.

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

For now the supported configurations are `java_args`, `nodeSelector`, `license`, `affinity`, `tolerations`, `topologySpreadConstraints`

For more information about node scheduling options see https://kubernetes.io/docs/concepts/scheduling-eviction

It is also possible to set additional JMX attributes after the cluster is initialized. This applies only to the master nodes and is configured using the `graphdb.masters.additionalJmxArrtibutes`.
This is a map in which the key is the attribute name and the value - the attribute value.

For example if you wish to set the maximum transaction log size, you can do so by setting the following in `values.yaml`:

```yaml
graphdb:
  masters:
    additionalJmxArrtibutes:
      LogMaxSize: 10
```

A list of available JMX attributes can be found [here](https://graphdb.ontotext.com/documentation/enterprise/ee/attributes.html)

#### Deploying GraphDB with security

GraphDB's Helm chart supports deploying GraphDB with or without security. This can be toggled through `graphdb.security.enabled`.
If it is deployed with security enabled, a special provisioning user is used for repository provisioning, cluster linking, health checks and so on.
Additional users can be added through the settings file: `files/config/settings.js`. The users are described with their roles, username and a bcrypt64 password.

The file is provisioned before GraphDB's startup with the configmap `graphdb.masters.settingsConfigmap`.
It can be overridden with other configmap containing the `settings.js` file. The same configmap is used for the `graphdb.properties` file as well.
Note that the `provisioning` user is required when security is turned on!

By default if the security is turned on, GraphDB's basic security method is used. More complicated security configurations
can be configured using additional configurations in `graphdb.properties`.

See https://graphdb.ontotext.com/documentation/enterprise/access-control.html

#### Provisioning additional properties

Most of GraphDB's properties can be passed through `java_args`. Another option is to supply a `graphdb.properties` file.
This file is provisioned on all GraphDB instances during GraphDB's startup using configmap `graphdb.masters.settingsConfigmap`.
It can be overridden with other configmap containing the `graphdb.properties` file. The same configmap is used for the `settings.js` file as well.

The `graphdb.properties` file is also used for more complex security configurations such as LDAP, Oauth, Kerberos.

See https://graphdb.ontotext.com/documentation/enterprise/configuring-graphdb.html?highlight=properties
See https://graphdb.ontotext.com/documentation/enterprise/access-control.html

#### Backup, restore and cleanup options

GraphDB's Helm chart supports automatic backup, restore and cleanup procedures. There are a few options that are used to describe the required jobs that handle those tasks.

Those options are described in the subsection `graphdb.backupRestore.*` and they are:
- auto_backup - cron Schedule for auto backup. Creates an automatic backup, stored in a dynamically provisioned PV/PVC using `volumeClaimTemplates` (default folder - /data/graphdb-backups). The backups are saved in format repositoryName-YYYY-MM-DD-hh-mm
- cleanup_cron - cleans up the backups directory. Makes sure that there is a limit of the stored backups. Each or both of `backups_count` and `backups_max_age` could be used. **NOTE: This will work only with certain types of storage classes that support ReadWriteMany!**
- backups_count - max number of backup dirs saved.
- backup_max_age - max number of days for backups.
- trigger_backup - a future date at which we want to trigger a backup. Must be given in format YYYY-MM-DD hh:mm. Please bear in mind that there could be a time difference with the kubernetes environment
- trigger_restore - a future date at which we want to trigger a restore. Works only with a cluster with workers. For a standalone the restore is called from an init container. Must be given in format YYYY-MM-DD hh:mm
- restore_from_backup - the name of the backup directory we want to restore. Must be given in format YYYY-MM-DD hh:mm, where YYYY-MM-DD hh:mm is your backup directory
- restore_repository - the name of the repository that we want to restore.

#### Importing data from existing persistent volume
GraphDB supports attaching a folder as an import directory. The directory's content s visible in the Workbench and can be imported.
In the Helm chart you can use existing PV as an import directory. This is done through `graphdb.import_directory_mount` using a `volumeClaimTemplateSpec`.
This way a dynamic PV/PVC can be provisioned, or you can use an existing PV. If an existing PV is used, have in mind that the dynamically provisioned PVC name is `graphdb-server-import-dir-graphdb-master-1-0`, so an appropriate `claimRef` must be added to the existing PV.

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

### Networking

By default, GraphDB's Helm chart comes with a default Ingress and also Kong for more flexibility in configuring instances paths.
Both the Ingress and Kong can be disabled by switching `kong.enabled` and `ingress.enabled`.

### Cloud deployments specifics

Some cloud kubernetes clusters have some specifics that should be noted. Here are some useful tips on some cloud K8s clusters:

##### Google cloud

In Google's k8s cluster services, the root directory is not writable. By default GraphDB's chart uses `/data` directory to store instances data.
If you're using Google cloud, please change this path to something else, not located on the root level.

##### Microsoft Azure

We recommend not to use the Microsoft Azure storage of type `azurefile`. The write speeds of this storage type when used in a Kubernetes cluster is
not good enough for GraphDB and we recommend not to use it in production environments.

See https://github.com/Azure/AKS/issues/223

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
| global.imagePullSecrets | list | [] | List of additional image pull secrets. This will be concatenated with anything at a lower level |
| global.imageRegistry | string | docker.io | This is used as a global override for the image registry. If defined it takes precedence over `images.XYZ.registry` |
| global.storageClass | string | standard | Used as a default storage class when one is not provided explicitly at a lower level |
| global.deployment.host / global.ingressHost | string | Overrides the hostname at which graphdb will be exposed. The order of precedence is global.deplyment.host -> global.ingressHost -> deployment.host |  

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
| graphdb.backupRestore.auto_backup | string | `"*/5 * * * *"` | Cron Schedule for auto backup. Creates an automatic backup, stored in the graphdb-backup-pv (default folder - /data/graphdb-backups). The backups are saved in format MM-DD-YYYY-hh-mm in UTC! |
| graphdb.backupRestore.backup_max_age | string | `"2"` | Max number of days for backups. |
| graphdb.backupRestore.backups_count | string | `"2"` | Max number of backup dirs saved. |
| graphdb.backupRestore.cleanup_cron | string | `"*/2 * * * *"` | Cleans up the backups directory. Makes sure that there is a limit of the stored backups. Each or both of backups_count and backups_max_age could be used. |
| graphdb.backupRestore.enable_automatic_backups_cleanup | bool | `false` | Enables cleanup of the backups directory. WARNING!!! This can be used only by storage classes that have access mode ReadWriteMany because the backups PVC must be attached to a second pod. |
| graphdb.backupRestore.enable_backups | bool | `false` | Enable auto/manual backups. |
| graphdb.backupRestore.enable_restore | bool | `true` | Trigger restore at a given time from a given file. |
| graphdb.backupRestore.persistence.volumeClaimTemplateSpec.accessModes[0] | string | `"ReadWriteOnce"` |  |
| graphdb.backupRestore.persistence.volumeClaimTemplateSpec.resources.requests.storage | string | `"10Gi"` |  |
| graphdb.backupRestore.persistence.volumeClaimTemplateSpec.storageClassName | string | `"standard"` |  |
| graphdb.backupRestore.repositories[0] | string | `"default"` |  |
| graphdb.backupRestore.restore_from_backup | string | `"2021-06-24-12-59"` | The name of the backup directory we want to restore. Must be given in format YYYY-DD-MM-hh-mm, where YYYY-DD-MM-hh-mm is your backup directory. The backup directory name contains the repository name too, but it must be omitted here. |
| graphdb.backupRestore.restore_repository | string | `"default"` | The name of the repository we want to restore. |
| graphdb.backupRestore.trigger_backup | string | `""` | A future date at which we want to trigger a backup. Must be given in format YYYY-DD-MM hh:mm NOTE: UTC TIME IS USED! |
| graphdb.backupRestore.trigger_restore | string | `"2021-06-24 13:28"` | A future date at which we want to trigger a restore. Works only with a cluster with workers. For a standalone the restore is called from an init container. Must be given in format YYYY-DD-MM hh:mm NOTE: UTC TIME IS USED! |
| graphdb.clusterConfig.clusterSecret | string | `"s3cr37"` | A secret used for secure communication amongst the nodes in the cluster. |
| graphdb.clusterConfig.masterWorkerMapping | list | `["master-1 -> worker-1","master-1 -> worker-2","master-2 -> worker-3"]` | Describes how the masters and workers are linked in the format master-X -> worker-Y. Required only for 2m3w_muted topology. |
| graphdb.clusterConfig.mastersCount | int | `1` |  |
| graphdb.clusterConfig.mutedMasters | list | `["master-2"]` | Describes which masters will be set as muted. Required only for 2m3w_muted topology. |
| graphdb.clusterConfig.readOnlyMasters | list | `["master-2"]` | Describes which masters will be set as read only. Required only for 2m3w_rw_ro topology. |
| graphdb.clusterConfig.syncPeersMapping | list | `["master-1 <-> master-2"]` | Describes which masters will be linked as sync peer. Required for 2m3w_rw_ro and 2m3w_muted topology. |
| graphdb.clusterConfig.workersCount | int | `2` |  |
| graphdb.masters.java_args | string | `"-XX:MaxRAMPercentage=70 -XX:+UseContainerSupport -Ddefault.min.distinct.threshold=100m -Dgraphdb.home.work=/mnt/graphdb"` | Java arguments with which master instances will be launched. GraphDB configuration properties can also be passed here in the format -Dprop=value |
| graphdb.masters.license | string | `"graphdb-license"` | Reference to a secret containing 'graphdb.license' file to be used by master nodes. Can be set to "" (no license) if this GraphDB instance is used only with a "master" repository! Important: Must be created beforehand |
| graphdb.masters.nodes[0].java_args | string | `"-XX:MaxRAMPercentage=70 -XX:+UseContainerSupport -Ddefault.min.distinct.threshold=100m"` |  |
| graphdb.masters.nodes[0].license | string | `"graphdb-license"` |  |
| graphdb.masters.nodes[0].name | string | `"master-1"` |  |
| graphdb.masters.persistence | object | `{"storage":"10G","storageClassName":"standard","volumeNamePrefix":"graphdb-default-master"}` | Persistence configurations. By default, Helm will use a PV that reads and writes to the host file system. |
| graphdb.masters.persistence.storage | string | `"10G"` | Storage size request for each master. The persistent volume has to be able to satisfy the size. |
| graphdb.masters.persistence.volumeNamePrefix | string | `"graphdb-default-master"` | Name reference of a persistent volume to which the claim will try to attach. If changed, the default PVs won't be used. Example result: graphdb-default-master-1-pv |
| graphdb.masters.repositoryConfigmap | string | `"graphdb-repo-default-configmap"` | Reference to a configuration map containing one or more .ttl files used for repository initialization in the post install hook. For reference see https://graphdb.ontotext.com/documentation/standard/configuring-a-repository.html |
| graphdb.masters.resources | object | `{"limits":{"memory":"1Gi"},"requests":{"memory":"1Gi"}}` | Below are minimum requirements for data sets of up to 50 million RDF triples For resizing, refer according to your GraphDB version documentation For EE see http://graphdb.ontotext.com/documentation/enterprise/requirements.html |
| graphdb.masters.settingsConfigmap | string | `"graphdb-settings-default-configmap"` | Reference to a configuration map containing settings.js and graphdb.properties(optional) files used for security and properties provisioning in the post install hook. For reference see https://graphdb.ontotext.com/documentation/standard/configuring-graphdb.html |
| graphdb.security.enabled | bool | `false` |  |
| graphdb.security.provisioningPassword | string | `"iHaveSuperpowers"` |  |
| graphdb.security.provisioningUsername | string | `"provisioner"` |  |
| graphdb.tools | object | `{"loadrdf":{"flags":"-f","rdfDataFile":"geonames_europe.ttl","trigger":false},"persistence":{"storage":"10G","storageClassName":"standard"},"preload":{"flags":"-f","rdfDataFile":"geonames_europe.ttl","trigger":false},"resources":{"limits":{"memory":"10G"},"requests":{"memory":"10G"}},"storage_tool":{"command":"scan","options":"","repository":"repo-test-1","trigger":false}}` | Tools for loading, scanning and repairing data in repos |
| graphdb.tools.loadrdf | object | `{"flags":"-f","rdfDataFile":"geonames_europe.ttl","trigger":false}` | Tool to preload data in a chosen repo https://graphdb.ontotext.com/documentation/enterprise/loading-data-using-the-loadrdf-tool.html |
| graphdb.tools.loadrdf.flags | string | `"-f"` | Options to add to the command possible flags: -f, -p If you use the "-f" option, the tool will override the repository and could lose some data. |
| graphdb.tools.loadrdf.trigger | bool | `false` | If trigger is set to true, then the loadrdf tool will be run while initializing the deployment Don't forget to add repo config file(should be named config.ttl) and RDF data file to the graphdb-preload-data-pv (default pv is: /data/graphdb-worker-preload-data) |
| graphdb.tools.persistence.storage | string | `"10G"` | Storage size request for the preload/loadrdf pv. The persistent volume has to be able to satisfy the size. |
| graphdb.tools.preload | object | `{"flags":"-f","rdfDataFile":"geonames_europe.ttl","trigger":false}` | Tool to preload data in a chosen repo https://graphdb.ontotext.com/documentation/enterprise/loading-data-using-preload.html |
| graphdb.tools.preload.flags | string | `"-f"` | Options to add to the command possible flags: -f, -p, -r If you use the "-f" option, the tool will override the repository and could lose some data. |
| graphdb.tools.preload.trigger | bool | `false` | If trigger is set to true, then the preload tool will be run while initializing the deployment Don't forget to add repo config file(should be named config.ttl) and RDF data file to the graphdb-preload-data-pv (default pv is: /data/graphdb-worker-preload-data) |
| graphdb.tools.storage_tool | object | `{"command":"scan","options":"","repository":"repo-test-1","trigger":false}` | Tool for scanning and repairing data See https://graphdb.ontotext.com/documentation/enterprise/storage-tool.html |
| graphdb.tools.storage_tool.command | string | `"scan"` | commands to run the storage-tool with |
| graphdb.tools.storage_tool.options | string | `""` | additional options to run the storage-tool with |
| graphdb.tools.storage_tool.repository | string | `"repo-test-1"` | repo to run command on |
| graphdb.tools.storage_tool.trigger | bool | `false` | If trigger is set to true, then the storage tool will be run while initializing the deployment |
| graphdb.topology | string | `"1m_3w"` | Cluster topology to be used. Possible values: standalone, 1m_3w, 2m3w_rw_ro, 2m3w_muted. standalone - Launches single instance of GraphDB with a preconfigured worker repository. Masters and workers count is controlled by mastersCount and workersCount properties 1m_3w - 1 master and multiple workers. https://graphdb.ontotext.com/documentation/enterprise/ee/setting-up-a-cluster-with-one-master.html 2m3w_rw_ro - 2 masters, one of which is read only and multiple workers. https://graphdb.ontotext.com/documentation/enterprise/ee/setting-up-a-cluster-with-a-second-readonly-master.html 2m3w_muted - 2 masters, one of which is muted and multiple workers. https://graphdb.ontotext.com/documentation/enterprise/ee/setting-up-a-cluster-with-multiple-masters-with-dedicated-workers.html Note: If "standalone" is selected, the launched instance will use master-1 properties, but a worker repository will be created! |
| graphdb.workbench.subpath | string | `"/graphdb"` | This is the sub path at which GraphDB workbench can be opened. Should be configured in the API gateway (or any other proxy in front) |
| graphdb.workers.java_args | string | `"-XX:MaxRAMPercentage=70 -Ddefault.min.distinct.threshold=100m -XX:+UseContainerSupport"` | Java arguments with which worker instances will be launched. GraphDB configuration properties can also be passed here in the format -Dprop=value |
| graphdb.workers.license | string | `"graphdb-license"` | Reference to a secret containing 'graphdb.license' file to be used by worker nodes. This is a required secret without which GraphDB won't operate if you use SE/EE editions. Important: Must be created beforehand |
| graphdb.workers.nodes | list | `[{"license":"graphdb-license","name":"worker-1"},{"java_args":"-XX:MaxRAMPercentage=70 -Ddefault.min.distinct.threshold=100m -XX:+UseContainerSupport ","name":"worker-2"}]` | Specific GraphDB worker instances configurations. Supported properties for per node configuration are: license, java_args, graphdb_properties |
| graphdb.workers.persistence | object | `{"storage":"10G","storageClassName":"standard","volumeNamePrefix":"graphdb-default-worker"}` | Persistence configurations. By default, Helm will use a PV that reads and writes to the host file system. |
| graphdb.workers.persistence.storage | string | `"10G"` | Storage size request for each worker. The persistent volume has to be able to satisfy the size. |
| graphdb.workers.persistence.volumeNamePrefix | string | `"graphdb-default-worker"` | Name reference prefix of a persistent volume to which the claim will try to attach. If changed, the default PVs won't be used. Example result: graphdb-default-worker-1-pv |
| graphdb.workers.repositoryConfigmap | string | `"graphdb-worker-repo-default-configmap"` | Reference to a configuration map containing one or more .ttl files used for repository initialization in the post install hook. For reference see https://graphdb.ontotext.com/documentation/standard/configuring-a-repository.html |
| graphdb.workers.resources | object | `{"limits":{"memory":"1Gi"},"requests":{"memory":"1Gi"}}` | Below are minimum requirements for data sets of up to 50 million RDF triples For resizing, refer according to your GraphDB version documentation For EE see http://graphdb.ontotext.com/documentation/enterprise/requirements.html Note: Same as for the master node |
| graphdb.workers.topologySpreadConstraints | string | `nil` |  |
| images.busybox | map | `{repository: busybox, tag: "1.31"}` |  |
| images.graphdb | map | `{repository: ontotext/graphdb, tag: "9.9.0-ee"}` |  |
| images.kong | map | `{repository: kong, tag: "2.1-alpine"}` |  |
| ingress.enabled | bool | `true` |  |
| kong.configmap | string | `"kong-configmap"` | Reference to a configuration map with Kong configurations as environment variables. Override if you need to further configure Kong's system. See https://docs.konghq.com/2.0.x/configuration/ |
| kong.enabled | bool | `true` |  |
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
| versions.ingress | string | `"networking.k8s.io/v1"` |  |
| versions.job | string | `"batch/v1"` |  |
| versions.pv | string | `"v1"` |  |
| versions.pvc | string | `"v1"` |  |
| versions.secret | string | `"v1"` |  |
| versions.service | string | `"v1"` |  |
| versions.statefulset | string | `"apps/v1"` |  |
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

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Ontotext GraphDB team | graphdb-support@ontotext.com |  |
