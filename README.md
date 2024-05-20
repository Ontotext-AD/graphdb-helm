# Helm charts for GraphDB

[![CI](https://github.com/Ontotext-AD/graphdb-helm/actions/workflows/ci.yml/badge.svg)](https://github.com/Ontotext-AD/graphdb-helm/actions/workflows/ci.yml)
![Version: 11.0.0](https://img.shields.io/badge/Version-11.0.0-informational?style=flat-square)
![AppVersion: 10.6.2](https://img.shields.io/badge/AppVersion-10.6.2-informational?style=flat-square)

You can download the GraphDB Helm chart, including all sub-charts managed by Ontotext, from the [Ontotext Helm repository](https://maven.ontotext.com/repository/helm-public/).

## Install

### Version Compatability

> Important: Beginning from version 11, the Helm chart has its own release cycle and is no longer tied to the version of GraphDB!

| Helm chart version | GraphDB version |
|--------------------|-----------------|
| 11.0.0             | 10.7.0          |

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

It's important to define resource limitations for the Minikube environment, otherwise it will
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
By default, it's configured for `localhost` which is suitable for the `none` Minikube driver.
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

See this how-to https://www.howtogeek.com/27350/beginner-geek-how-to-edit-your-hosts-file/
about modifying the hosts file in different OS.

#### Secrets

If you have a GraphDB license, create a secret with a `graphdb.license`
data entry:

```bash
kubectl create secret generic graphdb-license --from-file graphdb.license
```
then add the secret name to the values.yaml file as `graphdb.node.license`

**Note**: Secret names can differ from the given examples in the [values.yaml](values.yaml), but their configurations should be updated
to refer to the correct ones. Note that the licenses can be set for all node instances. Please setup correctly according to the licensing agreements.

#### Updating an expired GraphDB license

When the helm chart is installed the license will be provisioned through the secret set in the `graphdb.node.license` value.
When a license expires you'll have to update the secret, so GraphDB instances don't get provisioned with the old license.
In order NOT to restart your current GraphDB instances, you can copy your new license named `graphdb.license` in your GraphDB pods in folder `/opt/graphdb/home/work`.
It's important to name your file exactly `graphdb.license`!

```bash
kubectl delete secret graphdb-license
kubectl create secret generic graphdb-license --from-file graphdb.license
kubectl cp graphdb.license graphdb-node-0:/opt/graphdb/home/work
```

**Note**: If you use a standalone GraphDB you can also change it through the workbench, but if you don't update the secret next restart will provision the old license.

### Cluster migration from GraphDB 9.x to 10.0

**Warning**: Before starting the migration change your master into read only mode. The process is irreversible and full backup is HIGHLY advisable. At minimum backup the PV of the worker you are planing to use for migration.

The Helm chart is completely new and not backwards-compatible.

1. Make all masters read only, you can use the workbench.
2. Using the workbench disconnect all repositories of the worker which we are going to use to migrate to 10.0.
If you've used the official GraphDB helm chart you can select any worker. In case of a custom implementation select one that can easily be scaled down.

 **Note**: Only the repositories that are on the worker will be migrated into the new cluster!
3. Get the PV information of the worker, noting down the capacity and the access mode:
   ```bash
   kubectl get pv
   ```
4. Note down the resource limits of the worker node:
   ```bash
   kubectl get pod graphdb-worker-<selected-worker> -o yaml | grep -B 2 memory
   ```
5. Make sure all the important settings saved in the settings.js of the master are present in the worker's. Their only difference
   should be the lack of locations in the worker's settings.
   ```bash
   kubectl cp graphdb-master-1-0:/opt/graphdb/home/work/workbench/settings.js settings_m.js
   kubectl cp graphdb-worker-<selected-worker>:/opt/graphdb/home/work/workbench/settings.js settings_w.js
   diff settings_m.js settings_w.js
   ```
   If anything other than the locations is different between the files assume that the master's file is correct and copy it to the worker:
   ```bash
   kubectl cp settings_m.js graphdb-worker-<selected-worker>:/opt/graphdb/home/work/workbench/settings.js
   ```
6. During a replication of a node GraphDB 10 can take double the storage which 9.x takes, so you might need to increase your PV size! To do this
   we recommend checking the documentation of your cloud service provider but in general the procedure is:
   - Make sure `allowVolumeExpansion: true` is set in your used storageClass.
   - Request a change in volume capacity by editing your PVC's `spec.resources.requests.storage`
   - Verify the change has taken effect with `get pvc <pvc-name> -o yaml` and checking the `status.capacity` field.
7. Scale down the selected worker. In the official GraphDB every worker has it's' own statefulset.
   List all the statefulsets to find the name of the worker you want to scale down:
   ```bash
   kubectl get statefulsets
   ```
   Then change the number of replicas to 0:
   ```bash
   kubectl scale statefulsets <stateful-set-name> --replicas=0
   ```
8. Once the worker is down patch the worker's PV with `"persistentVolumeReclaimPolicy":"Retain"`:
   ```bash
   kubectl patch pv <worker-pv-name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
   ```
9. Delete the worker's PVC.
   ```bash
   kubectl delete pvc <worker-pvc-name>
   ```
10. Patch the PV with `"claimRef":null` so it can go from status Released to Available:
    ```bash
    kubectl patch pv <worker-pv-name> -p '{"spec":{"claimRef":null}}'
    ```
11. Patch the PV with `claimRef` matching the PVC that will be generated by the `volumeClaimTemplates`:
    ```bash
    kubectl patch pv <worker-pv-name> -p '{"spec":{"claimRef":{"name":"graphdb-node-data-dynamic-pvc-graphdb-node-0"}}}'
    ```
12. Create a namespace for the GraphDB 10 helm chart, so we can deploy it without having to delete our 9.x cluster:
    ```bash
    kubectl create namespace <new-namespace-name>
    ```
13. Patch/Move the worker's PV to the new namespace:
    ```bash
    kubectl patch pv <worker-pv-name> -p '{"spec":{"claimRef":{"namespace":"<namespace-name>"}}}'
    ```
14. Create a secret with your license in the new namespace:
     ```bash
    graphdb-license --from-file graphdb.license -n <new-namespace-name>
    ```
15. Install the 10.0 Helm chart. Remember to edit:
- `graphdb.node.resources.limits.memory` and `graphdb.node.resources.requests.memory` to the ones used by the old workers.
- `graphdb.nodesCount:` The raft protocol recommends an odd amount of nodes. Set to the amount of workers you had in the old cluster.
- `graphdb.node.persistance.volumeClaimTemplateSpec.accessModes` and `graphdb.node.persistance.volumeClaimTemplateSpec.resources.requests.storage` to the ones used by the old PVs.
- `graphdb.clusetConfig.clusterCreationTimeout` high enough so the data from the old worker has time to replicate to all the new nodes. This depends on network speed between the nodes and the read/write performance of the storage. If the replication is expected to take more than 5 minutes add an equivalent `--timeout XXm` to the helm install command.
- `deployment.host` to temporary address where you can test everything is working.

16. Once you confirm everything has migrated and works as expected you can free up the old `deployment.host` and upgrade the new cluster to it.

**Note**: If you decide to revert to 9.x and don't have a backup of the worker's PV, you won't be able to use the old PV as GraphDB 10's repositories and settings aren't backward compatible.
Your best course of action would be to make sure it will provision a new clean PV, scale the replica back from 0, recreate the worker repositories and reconnect them to the old master repositories letting GraphDB replicate the data.

### Quick Start

The Helm chart includes an example repository configuration TTLs.

To install the GraphDB on `graphdb.local`:

```bash
helm install --set deployment.host=graphdb.local graphdb .
```

After a few seconds, Helm will print out the result from installing GraphDB.
You should see the following output:

```
-------------------------------------------------------------------------------
        ____                 _     ____  ____
       / ___|_ __ __ _ _ __ | |__ |  _ \| __ )
      | |  _| '__/ _` | '_ \| '_ \| | | |  _ \
      | |_| | | | (_| | |_) | | | | |_| | |_) |
       \____|_|  \__,_| .__/|_| |_|____/|____/
                      |_|
-------------------------------------------------------------------------------
version: 10.0.0
GDB cluster: true

** Please be patient while the chart is being deployed and services are available **
You can check their status with kubectl get pods

Endpoints:
* GraphDB workbench: http://graphdb.local/graphdb
```

### Repository

You can install GraphDB's Helm chart from our public Helm repository as well.

1. Add Ontotext repository with

    ```shell
    helm repo add ontotext https://maven.ontotext.com/repository/helm-public/
    ```

2. Install GraphDB

    ```shell
    helm install graphdb ontotext/graphdb
    ```

### Provenance

Helm can verify the origin and integrity of the Helm chart by

1. Importing the public GnuPG key:

    ```shell
    gpg --keyserver keyserver.ubuntu.com --recv-keys 8E1B45AF8157DB82
    # Helm uses the legacy gpg format
    gpg --export > ~/.gnupg/pubring.gpg
    ```

2. Running `helm install` with the `--verify` flag, i.e.:

    ```shell
    helm install --verify graphdb ontotext/graphdb
    ```

Note that the verification works only when installing from a local tar.gz or when installing from the repository.

## Persistence

By default, the Helm chart is deploying persistent volumes that store data on the host path.
This is useful for local Minikube deployments. However, in a cloud environment with multiple node
cluster this would lead to rescheduling and **data loss**.

See https://kubernetes.io/docs/concepts/storage/volumes/.

### Local deployment

Local persistent volumes are configured with `graphdb.node.persistence` from [values.yaml](values.yaml).

### Cloud deployment

For cloud deployment, you have to prepare persistent disks, storage class (or classes) and finally
persistent volumes manifests. Once this is done, every component must be reconfigured in
[values.yaml](values.yaml) to point to the new persistent volume and not the default one. Each
component has a section `persistence` that has to be updated.

## API Gateway

The services are proxied using nginx Ingress gateway. By default, it is configured to route:

- GraphDB Workbench
- GraphDB cluster proxy if the cluster deployment is enabled

## Customizing

Every component in configured with sensible defaults. Some of them are applied from
[values.yaml](values.yaml). Make sure you read it thoroughly, understand each property and the
impact of changing any one of them.

**Note**: If you are familiar with Kubernetes, you could modify the component's configuration
templates directly.

#### Ontop repositories

Ontop repositories require a jdbc driver. To use this type of repository, you have to provide a jdbc driver named `jdbc-driver.jar`.
It must be located in each GraphDB instance in which you wish to use with Ontop repository, in the folder `/opt/graphdb/home/jdbc-driver`.
The directory is part of the GraphDB home directory which is persistent, so the driver will persist after a restart or reschedule of a GraphDB pod.

### Customizing GraphDB cluster and GraphDB specific properties

GraphDB's Helm chart is made to be highly customizable regarding GraphDB's specific options and properties.
There are 3 important configuration sections:
- GraphDB cluster configuration
- GraphDB node configuration
- GraphDB cluster proxy configuration

#### GraphDB cluster configuration

With the release of GraphDB 10, master nodes are no longer needed for a cluster, so the size of the cluster is controlled by just one property: `graphdb.clusterConfig.nodesCount`.
You will need at least three GraphDB installations to create a fully functional cluster. Remember that the Raft algorithm recommends an odd number of nodes, so a cluster of five nodes is a good choice.

Note: If "1" is selected as node count, the launched node will be standalone and no instances of the cluster proxy will be deployed!

- The section `graphdb.clusterConfig` can be used to configure a GraphDB cluster.

See more about the cluster here: https://graphdb.ontotext.com/documentation/10.0/cluster-basics.html

#### Deploying GraphDB with security

GraphDB's Helm chart supports deploying GraphDB with or without security. This can be toggled through `graphdb.security.enabled`.
If it is deployed with security enabled, a special provisioning user is used for repository provisioning, cluster linking, health checks and so on.
Additional users can be added through the users file: `files/config/users.js`. The users are described with their roles, username and a bcrypt64 password.

The file can be provisioned before GraphDB's startup with the `usersConfigMap` configmap or left to default.
It can be overridden with other configmap containing the `users.js` file.
Note that the `provisioning` user is required when security is turned on!

By default, if the security is turned on, GraphDB's basic security method is used. More complicated security configurations
can be configured using additional configurations in `graphdb.properties`.

See https://graphdb.ontotext.com/documentation/10.0/access-control.html

Prior to GraphDB 10.0.0 the users and their settings were saved in the `settings.js` file.

#### Provisioning additional properties and settings

Most of GraphDB's properties can be passed through `java_args`. Another option is to supply a `graphdb.properties` file.
This file can be provisioned on during GraphDB's startup using `propertiesConfigMap`configmap or left to default.
It can be overridden with other configmap containing the `graphdb.properties` file.

The `graphdb.properties` file is also used for more complex security configurations such as LDAP, Oauth, Kerberos.

Some additional settings are kept in the `settings.js` file. Most of those settings are internal for GraphDB and better left managed by the client.
The file can be provisioned before GraphDB's startup with the `settingsConfigMap` configmap or left to default.
It can be overridden with other configmap containing the `settings.js` file.
Note the `settings.js` must contain `security.enabled" : true` property when security is turned on!

GraphDB uses logback to configure logging using the `logback.xml` file.
The file can be provisioned before GraphDB's startup with the `logbackConfigMap` configmap or left to default.
It can be overridden with other configmap containing the `logback.xml` file.

See https://graphdb.ontotext.com/documentation/10.0/configuring-graphdb.html?highlight=properties
See https://graphdb.ontotext.com/documentation/10.0/access-control.html

#### Importing data from existing persistent volume
GraphDB supports attaching a folder as an import directory. The directory's content s visible in the Workbench and can be imported.
In the Helm chart you can use existing PV as an import directory. This is done through `graphdb.import_directory_mount` using a `volumeClaimTemplateSpec`.
This way a dynamic PV/PVC can be provisioned, or you can use an existing PV. If an existing PV is used, have in mind that the dynamically provisioned PVC name is `graphdb-server-import-dir-graphdb-master-1-0`, so an appropriate `claimRef` must be added to the existing PV.

### Networking

By default, GraphDB's Helm chart comes with a default Ingress.
The Ingress =can be disabled by switching `ingress.enabled` to false.

### Cloud deployments specifics

Some cloud kubernetes clusters have some specifics that should be noted. Here are some useful tips on some cloud K8s clusters:

##### Google cloud

In Google's k8s cluster services, the root directory is not writable. By default, GraphDB's chart uses `/data` directory to store instances data.
If you're using Google cloud, please change this path to something else, not located on the root level.

By default, the ingress used in the helm chart utilizes NGINX as ingress.class.
The easiest way to make it work inside the GKE is by deploying a NGINX ingress controller. Information on how that can be achieved can be found here: https://cloud.google.com/community/tutorials/nginx-ingress-gke

##### Microsoft Azure

We recommend not to use the Microsoft Azure storage of type `azurefile`. The write speeds of this storage type when used in a Kubernetes cluster is
not good enough for GraphDB, and we recommend against using it in production environments.

See https://github.com/Azure/AKS/issues/223

### values.yaml

Helm allows you to override values from [values.yaml](values.yaml) in several ways.
See https://helm.sh/docs/chart_template_guide/values_files/.

- Preparing another *values.yaml*:

```bash
helm install graphdb . -f overrides.yaml
```

- Overriding specific values:

```bash
helm install graphdb . --set deployment.host=graphdb.local --set security.enabled=true
```

### Deployment

Some important properties to update according to your deployment are:

* `deployment.protocol` and `deployment.host` - configure the ingress
controller and some components on which they are accessible. The `deployment.host` must be a
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
| affinity | object | `{}` |  |
| annotations | object | `{}` |  |
| args | list | `[]` |  |
| automountServiceAccountToken | bool | `false` |  |
| cluster.clusterCreationTimeout | int | `60` |  |
| cluster.config.configmapKey | string | `"cluster-config.json"` |  |
| cluster.config.electionMinTimeout | int | `8000` |  |
| cluster.config.electionRangeTimeout | int | `6000` |  |
| cluster.config.existingConfigmap | string | `""` |  |
| cluster.config.heartbeatInterval | int | `2000` |  |
| cluster.config.messageSizeKB | int | `64` |  |
| cluster.config.transactionLogMaximumSizeGB | int | `50` |  |
| cluster.config.verificationTimeout | int | `1500` |  |
| cluster.jobs.createCluster.enabled | bool | `true` |  |
| cluster.jobs.patchCluster.enabled | bool | `true` |  |
| cluster.jobs.scaleCluster.enabled | bool | `true` |  |
| cluster.token.existingSecret | string | `""` |  |
| cluster.token.secret | string | `"s3cr37"` |  |
| cluster.token.secretKey | string | `""` |  |
| command | list | `[]` |  |
| configuration.defaultJavaArguments | string | `"-XX:+UseContainerSupport -XX:MaxRAMPercentage=70 -XX:-UseCompressedOops"` |  |
| configuration.externalUrl | string | `"http://graphdb.127.0.0.1.nip.io/"` |  |
| configuration.extraProperties.configmapKey | string | `"graphdb.properties"` |  |
| configuration.extraProperties.existingConfigmap | string | `""` |  |
| configuration.extraProperties.existingSecret | string | `""` |  |
| configuration.extraProperties.secretKey | string | `"graphdb.properties"` |  |
| configuration.initialSettings.configmapKey | string | `"settings.js"` |  |
| configuration.initialSettings.existingConfigmap | string | `""` |  |
| configuration.javaArguments | string | `""` |  |
| configuration.logback.configmapKey | string | `"logback.xml"` |  |
| configuration.logback.existingConfigmap | string | `""` |  |
| configuration.properties | object | `{}` |  |
| configuration.secretProperties | object | `{}` |  |
| containerPorts.http | int | `7200` |  |
| containerPorts.rpc | int | `7300` |  |
| dnsConfig | object | `{}` |  |
| dnsPolicy | string | `""` |  |
| extraContainerPorts | object | `{}` |  |
| extraContainers | list | `[]` |  |
| extraEnv | list | `[]` |  |
| extraEnvFrom | list | `[]` |  |
| extraInitContainers | list | `[]` |  |
| extraObjects | list | `[]` |  |
| extraVolumeClaimTemplates | list | `[]` |  |
| extraVolumeMounts | list | `[]` |  |
| extraVolumes | list | `[]` |  |
| fullnameOverride | string | `""` |  |
| global.clusterDomain | string | `"cluster.local"` |  |
| global.imagePullSecrets | list | `[]` |  |
| global.imageRegistry | string | `""` |  |
| headlessService.annotations | object | `{}` |  |
| headlessService.enabled | bool | `true` |  |
| headlessService.labels | object | `{}` |  |
| headlessService.ports.http | int | `7200` |  |
| headlessService.ports.rpc | int | `7300` |  |
| image.digest | string | `"sha256:aabf1283664b1cbeeb9880025bbea6820c4a7f5a3a54e5940534e916b8829035"` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.pullSecrets | list | `[]` |  |
| image.registry | string | `"docker.io"` |  |
| image.repository | string | `"ontotext/graphdb"` |  |
| image.tag | string | `""` |  |
| import.volumeMount.enabled | bool | `false` |  |
| import.volumeMount.volumeClaimTemplate.annotations | object | `{}` |  |
| import.volumeMount.volumeClaimTemplate.labels | object | `{}` |  |
| import.volumeMount.volumeClaimTemplate.spec.accessModes[0] | string | `"ReadWriteOnce"` |  |
| import.volumeMount.volumeClaimTemplate.spec.resources.requests.storage | string | `"10Gi"` |  |
| ingress.annotations | object | `{}` |  |
| ingress.className | string | `""` |  |
| ingress.enabled | bool | `true` |  |
| ingress.extraHosts | list | `[]` |  |
| ingress.extraTLS | list | `[]` |  |
| ingress.host | string | `""` |  |
| ingress.labels | object | `{}` |  |
| ingress.path | string | `""` |  |
| ingress.pathType | string | `"Prefix"` |  |
| ingress.tls.enabled | bool | `false` |  |
| ingress.tls.secretName | string | `nil` |  |
| initContainerDataPermissions.enabled | bool | `false` |  |
| initContainerDataPermissions.securityContext.runAsNonRoot | bool | `false` |  |
| initContainerDataPermissions.securityContext.runAsUser | int | `0` |  |
| initContainerResources.limits.cpu | string | `"50m"` |  |
| initContainerResources.limits.memory | string | `"16Mi"` |  |
| initContainerResources.requests.cpu | string | `"50m"` |  |
| initContainerResources.requests.memory | string | `"16Mi"` |  |
| initContainerSecurityContext.allowPrivilegeEscalation | bool | `false` |  |
| initContainerSecurityContext.capabilities.drop[0] | string | `"ALL"` |  |
| initContainerSecurityContext.readOnlyRootFilesystem | bool | `true` |  |
| initContainerSecurityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| jobs.backoffLimit | int | `10` |  |
| jobs.persistence.emptyDir.sizeLimit | string | `"10Mi"` |  |
| jobs.podSecurityContext.fsGroup | int | `10001` |  |
| jobs.podSecurityContext.fsGroupChangePolicy | string | `"OnRootMismatch"` |  |
| jobs.podSecurityContext.runAsGroup | int | `10001` |  |
| jobs.podSecurityContext.runAsNonRoot | bool | `true` |  |
| jobs.podSecurityContext.runAsUser | int | `10001` |  |
| jobs.podSecurityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| jobs.resources.limits.cpu | string | `"50m"` |  |
| jobs.resources.limits.ephemeral-storage | string | `"10Mi"` |  |
| jobs.resources.limits.memory | string | `"16Mi"` |  |
| jobs.resources.requests.cpu | string | `"50m"` |  |
| jobs.resources.requests.ephemeral-storage | string | `"10Mi"` |  |
| jobs.resources.requests.memory | string | `"16Mi"` |  |
| jobs.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| jobs.securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| jobs.securityContext.readOnlyRootFilesystem | bool | `true` |  |
| jobs.securityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| jobs.ttlSecondsAfterFinished | int | `300` |  |
| labels | object | `{}` |  |
| license.existingSecret | string | `""` |  |
| license.licenseFilename | string | `"graphdb.license"` |  |
| livenessProbe.httpGet.path | string | `"/protocol"` |  |
| livenessProbe.httpGet.port | string | `"http"` |  |
| livenessProbe.initialDelaySeconds | int | `60` |  |
| livenessProbe.periodSeconds | int | `10` |  |
| livenessProbe.timeoutSeconds | int | `5` |  |
| nameOverride | string | `""` |  |
| namespaceOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| persistence.emptyDir.sizeLimit | string | `"1Gi"` |  |
| persistence.enabled | bool | `true` |  |
| persistence.volumeClaimTemplate.annotations | object | `{}` |  |
| persistence.volumeClaimTemplate.labels | object | `{}` |  |
| persistence.volumeClaimTemplate.spec.accessModes[0] | string | `"ReadWriteOnce"` |  |
| persistence.volumeClaimTemplate.spec.resources.requests.storage | string | `"5Gi"` |  |
| podAnnotations | object | `{}` |  |
| podDisruptionBudget.enabled | bool | `true` |  |
| podDisruptionBudget.maxUnavailable | string | `""` |  |
| podDisruptionBudget.minAvailable | string | `"51%"` |  |
| podLabels | object | `{}` |  |
| podManagementPolicy | string | `"Parallel"` |  |
| podSecurityContext.fsGroup | int | `10001` |  |
| podSecurityContext.fsGroupChangePolicy | string | `"OnRootMismatch"` |  |
| podSecurityContext.runAsGroup | int | `10001` |  |
| podSecurityContext.runAsNonRoot | bool | `true` |  |
| podSecurityContext.runAsUser | int | `10001` |  |
| podSecurityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| proxy.affinity | object | `{}` |  |
| proxy.annotations | object | `{}` |  |
| proxy.args | list | `[]` |  |
| proxy.command | list | `[]` |  |
| proxy.configuration.defaultJavaArguments | string | `"-XX:+UseContainerSupport -XX:MaxRAMPercentage=70"` |  |
| proxy.configuration.extraProperties.configmapKey | string | `"graphdb.properties"` |  |
| proxy.configuration.extraProperties.existingConfigmap | string | `""` |  |
| proxy.configuration.extraProperties.existingSecret | string | `""` |  |
| proxy.configuration.extraProperties.secretKey | string | `"graphdb.properties"` |  |
| proxy.configuration.javaArguments | string | `""` |  |
| proxy.configuration.logback.configmapKey | string | `"logback.xml"` |  |
| proxy.configuration.logback.existingConfigmap | string | `""` |  |
| proxy.configuration.properties | object | `{}` |  |
| proxy.configuration.secretProperties | object | `{}` |  |
| proxy.containerPorts.http | int | `7200` |  |
| proxy.containerPorts.rpc | int | `7300` |  |
| proxy.dnsConfig | object | `{}` |  |
| proxy.dnsPolicy | string | `""` |  |
| proxy.extraContainerPorts | object | `{}` |  |
| proxy.extraContainers | list | `[]` |  |
| proxy.extraEnv | list | `[]` |  |
| proxy.extraEnvFrom | list | `[]` |  |
| proxy.extraInitContainers | list | `[]` |  |
| proxy.extraVolumeClaimTemplates | list | `[]` |  |
| proxy.extraVolumeMounts | list | `[]` |  |
| proxy.extraVolumes | list | `[]` |  |
| proxy.fullnameOverride | string | `""` |  |
| proxy.headlessService.annotations | object | `{}` |  |
| proxy.headlessService.enabled | bool | `true` |  |
| proxy.headlessService.labels | object | `{}` |  |
| proxy.headlessService.ports.http | int | `7200` |  |
| proxy.headlessService.ports.rpc | int | `7300` |  |
| proxy.initContainerDataPermissions.enabled | bool | `false` |  |
| proxy.initContainerDataPermissions.securityContext.runAsNonRoot | bool | `false` |  |
| proxy.initContainerDataPermissions.securityContext.runAsUser | int | `0` |  |
| proxy.initContainerResources.limits.cpu | string | `"50m"` |  |
| proxy.initContainerResources.limits.memory | string | `"16Mi"` |  |
| proxy.initContainerResources.requests.cpu | string | `"50m"` |  |
| proxy.initContainerResources.requests.memory | string | `"16Mi"` |  |
| proxy.initContainerSecurityContext.allowPrivilegeEscalation | bool | `false` |  |
| proxy.initContainerSecurityContext.capabilities.drop[0] | string | `"ALL"` |  |
| proxy.initContainerSecurityContext.readOnlyRootFilesystem | bool | `true` |  |
| proxy.initContainerSecurityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| proxy.labels | object | `{}` |  |
| proxy.livenessProbe.httpGet.path | string | `"/proxy/health"` |  |
| proxy.livenessProbe.httpGet.port | string | `"http"` |  |
| proxy.livenessProbe.initialDelaySeconds | int | `120` |  |
| proxy.livenessProbe.periodSeconds | int | `10` |  |
| proxy.livenessProbe.timeoutSeconds | int | `5` |  |
| proxy.nameOverride | string | `""` |  |
| proxy.nodeSelector | object | `{}` |  |
| proxy.persistence.emptyDir.sizeLimit | string | `"500Mi"` |  |
| proxy.persistence.enabled | bool | `true` |  |
| proxy.persistence.volumeClaimTemplate.annotations | object | `{}` |  |
| proxy.persistence.volumeClaimTemplate.labels | object | `{}` |  |
| proxy.persistence.volumeClaimTemplate.spec.accessModes[0] | string | `"ReadWriteOnce"` |  |
| proxy.persistence.volumeClaimTemplate.spec.resources.requests.storage | string | `"500Mi"` |  |
| proxy.podAnnotations | object | `{}` |  |
| proxy.podDisruptionBudget.enabled | bool | `true` |  |
| proxy.podDisruptionBudget.maxUnavailable | string | `""` |  |
| proxy.podDisruptionBudget.minAvailable | string | `"51%"` |  |
| proxy.podLabels | object | `{}` |  |
| proxy.podManagementPolicy | string | `"Parallel"` |  |
| proxy.podSecurityContext.fsGroup | int | `10001` |  |
| proxy.podSecurityContext.fsGroupChangePolicy | string | `"OnRootMismatch"` |  |
| proxy.podSecurityContext.runAsGroup | int | `10001` |  |
| proxy.podSecurityContext.runAsNonRoot | bool | `true` |  |
| proxy.podSecurityContext.runAsUser | int | `10001` |  |
| proxy.podSecurityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| proxy.readinessProbe.httpGet.path | string | `"/proxy/ready"` |  |
| proxy.readinessProbe.httpGet.port | string | `"http"` |  |
| proxy.readinessProbe.periodSeconds | int | `10` |  |
| proxy.readinessProbe.timeoutSeconds | int | `5` |  |
| proxy.replicas | int | `1` |  |
| proxy.resources.limits.memory | string | `"1500Mi"` |  |
| proxy.resources.requests.cpu | string | `"100m"` |  |
| proxy.resources.requests.memory | string | `"1500Mi"` |  |
| proxy.revisionHistoryLimit | int | `10` |  |
| proxy.schedulerName | string | `""` |  |
| proxy.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| proxy.securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| proxy.securityContext.readOnlyRootFilesystem | bool | `true` |  |
| proxy.securityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| proxy.service.annotations | object | `{}` |  |
| proxy.service.enabled | bool | `true` |  |
| proxy.service.externalIPs | list | `[]` |  |
| proxy.service.externalTrafficPolicy | string | `""` |  |
| proxy.service.extraPorts | list | `[]` |  |
| proxy.service.healthCheckNodePort | string | `""` |  |
| proxy.service.labels | object | `{}` |  |
| proxy.service.loadBalancerClass | string | `""` |  |
| proxy.service.loadBalancerSourceRanges | list | `[]` |  |
| proxy.service.nodePort | string | `""` |  |
| proxy.service.ports.http | int | `7200` |  |
| proxy.service.type | string | `"ClusterIP"` |  |
| proxy.startupProbe.failureThreshold | int | `60` |  |
| proxy.startupProbe.httpGet.path | string | `"/proxy/ready"` |  |
| proxy.startupProbe.httpGet.port | string | `"http"` |  |
| proxy.startupProbe.periodSeconds | int | `5` |  |
| proxy.startupProbe.timeoutSeconds | int | `3` |  |
| proxy.terminationGracePeriodSeconds | int | `30` |  |
| proxy.tolerations | list | `[]` |  |
| proxy.topologySpreadConstraints | list | `[]` |  |
| proxy.updateStrategy.type | string | `"RollingUpdate"` |  |
| readinessProbe.httpGet.path | string | `"/protocol"` |  |
| readinessProbe.httpGet.port | string | `"http"` |  |
| readinessProbe.initialDelaySeconds | int | `5` |  |
| readinessProbe.periodSeconds | int | `10` |  |
| readinessProbe.timeoutSeconds | int | `5` |  |
| replicas | int | `1` |  |
| repositories.existingConfigmap | string | `""` |  |
| resources.limits.memory | string | `"2Gi"` |  |
| resources.requests.cpu | string | `"500m"` |  |
| resources.requests.memory | string | `"2Gi"` |  |
| revisionHistoryLimit | int | `10` |  |
| schedulerName | string | `""` |  |
| security.admin.initialPassword | string | `""` |  |
| security.admin.username | string | `"admin"` |  |
| security.enabled | bool | `false` |  |
| security.initialUsers.existingSecret | string | `""` |  |
| security.initialUsers.secretKey | string | `"users.js"` |  |
| security.initialUsers.users | object | `{}` |  |
| security.provisioner.existingSecret | string | `""` |  |
| security.provisioner.password | string | `"iHaveSuperpowers"` |  |
| security.provisioner.tokenKey | string | `"GRAPHDB_AUTH_TOKEN"` |  |
| security.provisioner.username | string | `"provisioner"` |  |
| securityContext.allowPrivilegeEscalation | bool | `false` |  |
| securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| securityContext.readOnlyRootFilesystem | bool | `true` |  |
| securityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| service.annotations | object | `{}` |  |
| service.enabled | bool | `true` |  |
| service.externalIPs | list | `[]` |  |
| service.externalTrafficPolicy | string | `""` |  |
| service.extraPorts | list | `[]` |  |
| service.healthCheckNodePort | string | `""` |  |
| service.labels | object | `{}` |  |
| service.loadBalancerClass | string | `""` |  |
| service.loadBalancerSourceRanges | list | `[]` |  |
| service.nodePort | string | `""` |  |
| service.ports.http | int | `7200` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `false` |  |
| serviceAccount.name | string | `""` |  |
| startupProbe.failureThreshold | int | `30` |  |
| startupProbe.httpGet.path | string | `"/protocol"` |  |
| startupProbe.httpGet.port | string | `"http"` |  |
| startupProbe.periodSeconds | int | `10` |  |
| startupProbe.timeoutSeconds | int | `5` |  |
| terminationGracePeriodSeconds | int | `120` |  |
| tolerations | list | `[]` |  |
| topologySpreadConstraints | list | `[]` |  |
| updateStrategy.type | string | `"RollingUpdate"` |  |

## Uninstall
To remove the deployed GraphDB, use:

```bash
helm uninstall graphdb
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
| Ontotext GraphDB team | <graphdb-support@ontotext.com> |  |
