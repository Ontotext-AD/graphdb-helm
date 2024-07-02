# Helm Chart for GraphDB

[![CI](https://github.com/Ontotext-AD/graphdb-helm/actions/workflows/ci.yml/badge.svg)](https://github.com/Ontotext-AD/graphdb-helm/actions/workflows/ci.yml)
![Version: 11.0.1](https://img.shields.io/badge/Version-11.0.1-informational?style=flat-square)
![AppVersion: 10.6.4](https://img.shields.io/badge/AppVersion-10.6.4-informational?style=flat-square)

<!--
TODO: Add ArtifactHub badge when ready
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/ontotext)](https://artifacthub.io/packages/helm/ontotext/graphdb)
-->

Welcome to the official [Helm](https://helm.sh/) chart repository for [GraphDB](https://www.ontotext.com/products/graphdb/)!
This Helm chart makes it easy to deploy and manage [GraphDB](https://www.ontotext.com/products/graphdb/) on your [Kubernetes](https://kubernetes.io/) cluster.

---

:warning: **Important**: Beginning from version 11, the Helm chart has its own release cycle and is no longer tied to the version of GraphDB.

---

## Quickstart

```shell
helm repo add ontotext https://maven.ontotext.com/repository/helm-public/
helm install graphdb ontotext/graphdb
```

## About GraphDB

<p align="center">
  <a href="https://www.ontotext.com/products/graphdb/">
    <picture>
      <img src="https://www.ontotext.com/wp-content/uploads/2022/09/Logo-GraphDB.svg" alt="GraphDB logo" title="GraphDB" height="75">
    </picture>
  </a>
</p>

Ontotext GraphDB is a highly efficient, scalable and robust graph database with RDF and SPARQL support. With excellent enterprise features,
integration with external search applications, compatibility with industry standards, and both community and commercial support, GraphDB is the
preferred database choice of both small independent developers and big enterprises.

<!--
TODO: Info about the basic Helm chart features ?
## Features
-->

## Prerequisites

* Kubernetes v1.26+
* Helm v3.8+

### Getting Started

If this is your first time installing a Helm chart, you should read the following introductions before continuing:

- Docker https://docs.docker.com/get-started/
- Kubernetes concepts https://kubernetes.io/docs/concepts/
- Helm https://helm.sh/docs/intro/quickstart/

After getting familiar with the above, you need to install the following binaries on your machine:

- Install Helm 3: https://helm.sh/docs/intro/install/
- Install `kubectl`: https://kubernetes.io/docs/tasks/tools/install-kubectl/

Next, you would need access to a Kubernetes cluster. You can set up a local one or use one of the cloud providers, e.g.:

* Minikube https://minikube.sigs.k8s.io/docs/
* kind https://kind.sigs.k8s.io/
* Amazon EKS https://aws.amazon.com/eks/
* Azure AKS https://azure.microsoft.com/en-us/products/kubernetes-service
* Google GKE https://cloud.google.com/kubernetes-engine

### GraphDB License

To use GraphDB Enterprise Edition features, you need a license.
If you have a GraphDB license, create a Secret object with a `graphdb.license` data entry:

```shell
kubectl create secret generic graphdb-license --from-file graphdb.license=graphdb.license
```

Then add the secret name to the values.yaml file under the `license.existingSecret` configuration.

**Note**: Secret names can differ from the given examples in the [values.yaml](values.yaml), but their configurations should be updated
to refer to the correct ones. Note that the licenses can be set for all node instances. Please setup correctly according to the licensing agreements.

## Install

### Version Compatability

The next table highlights the version mapping between the Helm chart and the deployed GraphDB.

| Helm chart version | GraphDB version |
|--------------------|-----------------|
| 10.x               | 10.0 - 10.6.4   |
| 11.0               | 10.6.4          |

### Install from Repository

1. Add Ontotext repository

    ```shell
    helm repo add ontotext https://maven.ontotext.com/repository/helm-public/
    ```

2. Install GraphDB

    ```shell
    helm install graphdb ontotext/graphdb
    ```

3. Upgrade GraphDB deployment

   ```shell
   helm upgrade --install graphdb ontotext/graphdb
   ```

See [Configuration](#configuration) and [values.yaml](values.yaml) on how to customize your GraphDB deployment.

### Provenance

Helm can verify the origin and integrity of the Helm chart by:

1. Importing the public GnuPG key for GraphDB Helm:

    ```shell
    gpg --keyserver keyserver.ubuntu.com --recv-keys 8E1B45AF8157DB82
    # Helm uses the legacy gpg format
    gpg --export > ~/.gnupg/pubring.gpg
    ```

2. Running `helm install` with the `--verify` flag, i.e.:

    ```shell
    helm install --verify graphdb ontotext/graphdb
    ```

**Note**: The verification works only when installing from a local tar.gz or when installing from the repository.

Check the official documentation for more information https://helm.sh/docs/topics/provenance/

### Uninstall

To remove the deployed GraphDB, use:

```shell
helm uninstall graphdb
```

**Note**: It is important to note that this will not remove any data, so the next time it is installed, the data will be loaded by its components.

## Upgrading

The Helm chart follows [Semantic Versioning v2](https://semver.org/) so any breaking changes will be rolled out only in MAJOR versions of the chart.

Please, always check out the migration guides in [UPGRADE.md](UPGRADE.md) before switching to another major version of the Helm chart.

## Configuration

Every component and resource is configured with sensible defaults in [values.yaml](values.yaml).
Make sure you read it thoroughly, understand each property and the impact of changing any one of them.

Helm allows you to override values from [values.yaml](values.yaml) in several ways.
See https://helm.sh/docs/chart_template_guide/values_files/.

* Using a separate values.yaml with overrides:
  ```shell
  helm install graphdb ontotext/graphdb -f overrides.yaml
  ```

* Overriding specific values:
  ```shell
  helm install graphdb ontotext/graphdb --set security.enabled=true
  ```

### Ontop repositories

Ontop repositories require a JDBC driver. To use this type of repository, you have to provide a JDBC driver named `jdbc-driver.jar`.
It must be located in each GraphDB instance in which you wish to use with Ontop repository, in the folder `/opt/graphdb/home/jdbc-driver`.
The directory is part of the GraphDB home directory which is persistent, so the driver will persist after a restart or reschedule of a GraphDB pod.

### Customizing GraphDB cluster and GraphDB specific properties

GraphDB's Helm chart is made to be highly customizable regarding GraphDB's specific options and properties.
There are 3 important configuration sections:
- GraphDB cluster configuration
- GraphDB node configuration
- GraphDB cluster proxy configuration

#### GraphDB cluster configuration

With the release of GraphDB 10, master nodes are no longer needed for a cluster, so the size of the cluster is controlled by just one property: `replicas`.
You will need at least three GraphDB installations to create a fully functional cluster. Remember that the Raft algorithm recommends an odd number of nodes, so a cluster of five nodes is a good choice.

Note: If `1` is selected as node count, the launched node will be standalone and no instances of the cluster proxy will be deployed!

- The section `cluster.config` can be used to configure a GraphDB cluster.

See more about the cluster here: https://graphdb.ontotext.com/documentation/10.6/cluster-basics.html

### Deploying GraphDB with security

GraphDB's Helm chart supports deploying GraphDB with or without security. This can be toggled through `security.enabled`.
If it is deployed with security enabled, a special provisioning user is used for repository provisioning, cluster linking, health checks and so on.
Additional users can be added through the users file: `files/config/users.js`. The users are described with their roles, username and a bcrypt64 password.

The file can be provisioned before GraphDB's startup with the `security.initialUsers` configurations.
It can be overridden with other configmap containing the `users.js` file with `security.initialUsers.existingSecret`.
Note that the `provisioning` user is required when security is turned on!

By default, if the security is turned on, GraphDB's basic security method is used. More complicated security configurations
can be configured using additional configurations in `graphdb.properties`.

See https://graphdb.ontotext.com/documentation/10.6/access-control.html

Prior to GraphDB 10.0.0 the users and their settings were saved in the `settings.js` file.

### Provisioning additional properties and settings

Most of GraphDB's properties can be passed through `configuration.properties` or `configuration.javaArguments`.
Another option is to supply a `graphdb.properties` file.
This file can be provisioned on during GraphDB's startup using `configuration.extraProperties.existingConfigmap`.

The `graphdb.properties` file is also used for more complex security configurations such as LDAP, Oauth, Kerberos.

Some additional settings are kept in the `settings.js` file. Most of those settings are internal for GraphDB and better left managed by the client.
The file can be provisioned before GraphDB's startup with the `configuration.initialSettings.existingSecret` configuration.
Note the `settings.js` must contain `security.enabled" : true` property when security is turned on!

GraphDB uses Logback to configure logging using the `logback.xml` file.
The file can be provisioned before GraphDB's startup with the `configuration.logback.existingConfigmap` configuration.

See https://graphdb.ontotext.com/documentation/10.6/directories-and-config-properties.html#configuration-properties

See https://graphdb.ontotext.com/documentation/10.6/access-control.html

### Importing data from existing persistent volume

GraphDB supports attaching a folder as an import directory. The directory's content s visible in the Workbench and can be imported.
In the Helm chart you can use existing PV as an import directory. This is done through `import.volumeMount` using a `volumeClaimTemplateSpec`.
This way a dynamic PV/PVC can be provisioned, or you can use an existing PV with an appropriate `claimRef`.

### Networking

By default, GraphDB's Helm chart comes with a default Ingress.
The Ingress can be disabled by switching `ingress.enabled` to false.

### Cloud deployments specifics

Some cloud Kubernetes clusters have some specifics that should be noted. Here are some useful tips on some cloud K8s clusters:

##### Microsoft Azure

We recommend not to use the Microsoft Azure storage of type `azurefile`. The write speeds of this storage type when used in a Kubernetes cluster is
not good enough for GraphDB, and we recommend against using it in production environments.

See https://github.com/Azure/AKS/issues/223

### Deployment

Some important properties to update according to your deployment are:

* `configuration.externalUrl` - Configures the address at which the Ingress controller and GraphDB are accessible.

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

## Examples

Checkout the [examples/](examples) folder in this repository.

## Guides

### Updating an expired GraphDB license

When the license expires, you will have to update the Secret object and restart the GraphDB pods in order to load the new license.

In avoid restarting your current GraphDB instances, you can copy the new license directly into your GraphDB containers, in the folder `/opt/graphdb/home/conf`.
It's important to name your file exactly `graphdb.license`!

```shell
kubectl delete secret graphdb-license
kubectl create secret generic graphdb-license --from-file graphdb.license=graphdb.license
kubectl cp graphdb.license graphdb-pod-0:/opt/graphdb/home/conf/
kubectl cp graphdb.license graphdb-pod-1:/opt/graphdb/home/conf/
kubectl cp graphdb.license graphdb-pod-2:/opt/graphdb/home/conf/
```

## Values

<!--
IMPORTANT: This is generated by helm-docs, do not attempt modifying it on hand as it will be automatically generated.
-->

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| annotations | object | `{}` |  |
| args | list | `[]` |  |
| automountServiceAccountToken | bool | `false` |  |
| cluster.clusterCreationTimeout | int | `60` |  |
| cluster.config.configmapKey | string | `"cluster-config.json"` |  |
| cluster.config.existingConfigmap | string | `""` |  |
| cluster.config.params.electionMinTimeout | int | `8000` |  |
| cluster.config.params.electionRangeTimeout | int | `6000` |  |
| cluster.config.params.heartbeatInterval | int | `2000` |  |
| cluster.config.params.messageSizeKB | int | `64` |  |
| cluster.config.params.transactionLogMaximumSizeGB | int | `50` |  |
| cluster.config.params.verificationTimeout | int | `1500` |  |
| cluster.jobs.createCluster.enabled | bool | `true` |  |
| cluster.jobs.patchCluster.enabled | bool | `true` |  |
| cluster.jobs.scaleCluster.enabled | bool | `true` |  |
| cluster.token.existingSecret | string | `""` |  |
| cluster.token.secret | string | `"s3cr37"` |  |
| cluster.token.secretKey | string | `""` |  |
| command | list | `[]` |  |
| configuration.defaultJavaArguments | string | `"-XX:+UseContainerSupport -XX:MaxRAMPercentage=70 -XX:-UseCompressedOops -Ddefault.min.distinct.threshold=100m"` |  |
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
| headlessService.extraPorts | list | `[]` |  |
| headlessService.labels | object | `{}` |  |
| headlessService.ports.http | int | `7200` |  |
| headlessService.ports.rpc | int | `7300` |  |
| image.digest | string | `""` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.pullSecrets | list | `[]` |  |
| image.registry | string | `"docker.io"` |  |
| image.repository | string | `"ontotext/graphdb"` |  |
| image.tag | string | `""` |  |
| import.volumeMount.enabled | bool | `false` |  |
| import.volumeMount.volumeClaimTemplate.annotations | object | `{}` |  |
| import.volumeMount.volumeClaimTemplate.labels | object | `{}` |  |
| import.volumeMount.volumeClaimTemplate.name | string | `"import"` |  |
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
| persistence.volumeClaimTemplate.name | string | `"storage"` |  |
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
| priorityClassName | string | `""` |  |
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
| proxy.headlessService.extraPorts | list | `[]` |  |
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
| proxy.persistence.volumeClaimTemplate.name | string | `"storage"` |  |
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
| proxy.priorityClassName | string | `""` |  |
| proxy.readinessProbe.httpGet.path | string | `"/proxy/ready"` |  |
| proxy.readinessProbe.httpGet.port | string | `"http"` |  |
| proxy.readinessProbe.periodSeconds | int | `10` |  |
| proxy.readinessProbe.timeoutSeconds | int | `5` |  |
| proxy.replicas | int | `3` |  |
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
| resources.limits.memory | string | `"4Gi"` |  |
| resources.requests.cpu | string | `"500m"` |  |
| resources.requests.memory | string | `"4Gi"` |  |
| revisionHistoryLimit | int | `10` |  |
| schedulerName | string | `""` |  |
| security.admin.initialPassword | string | `""` |  |
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
| tempVolume.emptyDir.sizeLimit | string | `"128Mi"` |  |
| tempVolume.enabled | bool | `true` |  |
| terminationGracePeriodSeconds | int | `120` |  |
| tolerations | list | `[]` |  |
| topologySpreadConstraints | list | `[]` |  |
| updateStrategy.type | string | `"RollingUpdate"` |  |

## Troubleshooting

**Helm install hangs**

If there is no output after `helm install`, it is likely that a hook cannot execute.
Check their logs with `kubectl logs`.

Another reason could be that the default timeout of 5 minutes for Helm `install` or `upgrade` is not enough.
You can increase the timeout by adding `--timeout 10m` (or more) to the Helm command.

**Connection issues**

If connections time out or the pods cannot resolve each other, it is likely that the Kubernetes
DNS is broken. This is a common issue with Minikube between system restarts or when inappropriate
Minikube driver is used. Please refer to
https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Ontotext GraphDB team | <graphdb-support@ontotext.com> |  |

## Contributing

If you have any suggestions, bug reports, or feature requests, please open an issue or submit a pull request.

## License

This code is released under the Apache 2.0 License. See [LICENSE](LICENSE) for more details.
