# GraphDB Helm chart release notes

## Version 11.2.0

### New

- Added CronJob for scheduling GraphDB backups. The CronJob supports both local and cloud backups.
    - Added new configurations under `backup`: `backup.enabled` for toggling the backup CronJob, `backup.type` for selecting between local and
      cloud and more.
    - Local backups support saving the GraphDB backup archives in volume from an existing persistent volume claim, configured
      with `backup.local`
    - Cloud backups support uploading the GraphDB backup archives in one of the supported cloud object storage services, configured
      with `backup.cloud`
    - Added a new example under [examples/backup-local](examples/backup-local) showing how to use the local backup feature

### Fixed

- Updated the GraphDB containers to explicitly use `/tmp` as a working directory to avoid permission errors due to the
  default security context's `readOnlyRootFilesystem` when the container has a starting folder different from `/tmp`.

## Version 11.1.3

### New

- Updated to GraphDB [10.7.3](https://graphdb.ontotext.com/documentation/10.7/release-notes.html#graphdb-10-7-3)

## Version 11.1.2

### New 

- Updated to GraphDB [10.7.2](https://graphdb.ontotext.com/documentation/10.7/release-notes.html#graphdb-10-7-2)

### Improvements

- Add examples for deploying GraphDB in AWS

## Version 11.1.1

### New

- Updated to GraphDB [10.7.1](https://graphdb.ontotext.com/documentation/10.7/release-notes.html#graphdb-10-7-1)

## Version 11.1.0

### New

- Updated to GraphDB [10.7.0](https://graphdb.ontotext.com/documentation/10.7/release-notes.html#graphdb-10-7-0)
- Added `podAntiAffinity` and `proxy.podAntiAffinity` for configuring a default podAntiAffinity for the GraphDB pods and
  GraphDB proxy pods. The default values configure a "soft" podAntiAffinity that tries to schedule GraphDB pods across
  different Kubernetes hosts but does not enforce it.
- Added new configuration options for the Jobs
    - Added `job.schedulerName` for overriding the default Kubernetes scheduler
    - Added `job.dnsConfig` and `job.dnsPolicy` for customizing the DNS resolution
    - Added `job.priorityClassName` for defining the pods scheduling importance
    - Added `job.nodeSelector`, `job.affinity`, `job.tolerations` and `job.topologySpreadConstraints` for customizing the
      node scheduling
- Added `persistence.volumeClaimRetentionPolicy` and `proxy.persistence.volumeClaimRetentionPolicy` to control the
  retention policy of the PVCs when the StatefulSets are scaled and deleted. These configurations are used only for
  Kubernetes 1.27 and above.

## Version 11.0.1

GraphDB Helm 11.0.1 is a patch release that includes bug fixes.

### Fixed

- Updated all cluster jobs to explicitly use `/tmp` as a working directory to avoid permission errors due to the default security
  context's `readOnlyRootFilesystem` when the container has a starting folder different from `/tmp`.
- Updated all utility scripts to use temporary files under `/tmp` for the same reason.

## Version 11.0.0

Version 11 of the chart addresses a bunch of legacy issues and aims to provide much better user experience and reliability.

### Highlights

* Version - The Helm chart is no longer tied with the version of GraphDB and has a separate development and release cycle.
* Naming - Removed hardcoded resource names in favor of using the name templates from [_labels.tpl](templates/_labels.tpl)
* Labels - Added the possibility to provide custom labels and annotations to almost every single resource
* Implementation Agnostic - Removed the dependency of particular ingress controllers and storage classes
* Security - Enabled security context by default
* Configurations - Added multiple new configurations to customize both GraphDB and the Kubernetes resources

### Breaking

- Updated the chart to require Kubernetes version 1.26+
- Enabled security context by default for all pods and containers
- Updated the GraphDB deployment URL to be http://graphdb.127.0.0.1.nip.io/ by default, see `configuration.externalUrl`
- Resource names are no longer hardcoded and are using the templates for `nameOverride` and `fullnameOverride`
- Updated the ingress to be agnostic to the ingress implementation. It will no longer assume that NGINX is the ingress controller in the
  cluster and will no longer deploy NGINX specific annotations by default. Removed anything related to NGINX as configurations.
- Removed setting FQDN as hostnames in GraphDB and the proxy in favor of dynamically resolving and configuring the hostnames in the provisioning init
  containers
- Removed the default value from `global.imageRegistry`, the chart now uses the value from `image.registry`
- Removed `global.storageClass` in favor of using by default the default storage class in the cluster. Templates will no longer
  use `global.storageClass`.
- Renamed `extraLabels` to just `labels`
- Moved `images.graphdb` configurations to just `image`
- Moved `deployment.imagePullPolicy` to `image.pullPolicy` and `deployment.imagePullSecret` to `image.pullSecrets`
  - Note that `image.pullSecrets` is now a list
- Moved `deployment.ingress` to just `ingress`
- Moved `deployment.tls` to `ingress.tls`
- Moved `graphdb` and `graphdb.node` configurations on the root level
- Moved all proxy configurations from `graphdb.clusterProxy` to just `proxy`
- Renamed `proxy.persistence.enablePersistence` toggle to just `enabled`
- Moved `proxy.serviceType` to `proxy.service.type`
- Configmaps from `graphdb.configs` are now under `configuration`, `repositories`, `cluster` and `security` with a different structure allowing
  better reuse of existing configmaps
- Moved `graphdb.clusterConfig` configurations
  - Moved `graphdb.clusterConfig.nodesCount` to `replicas`
  - Moved the rest of `graphdb.clusterConfig` configurations under `cluster`, `cluster.config` and `cluster.config.params`
- Moved `graphdb.security` configurations to `security`
  - Moved `provisioningUsername` and `provisioningPassword` under `security.provisioner`
- Moved job related configurations from `graphdb` (e.g. `graphdb.jobResources`) to a new root section `jobs`
- Moved `graphdb.node.service` configurations to `headlessService`
- Moved `graphdb.import_directory_mount` configurations to `import.volumeMount`
- Renamed `pdb` to `podDisruptionBudget` and renamed `podDisruptionBudget.create` to `podDisruptionBudget.enabled` for consistency
- Renamed `messageSize` to `messageSizeKB` in the cluster creation configuration in `cluster.config.params`
- Renamed `java_args` to `defaultJavaArguments` and added a separate `javaArguments` that can be used for additional configurations,
  see `configuration` and `proxy.configuration`
- Removed configuration overrides from the default `GDB_JAVA_OPTS`: `enable-context-index`, `entity-pool-implementation`
  and `health.max.query.time.seconds`
- Removed the default logback XML configuration and configmap in favor of an [example](examples/custom-logback) and a new configuration options
  under `configuration.logback` and `proxy.configuration.logback`
- Renamed GraphDB storage PVC template name prefix to `storage` and server import folder to `import`
- Moved `persistence.volumeClaimTemplateSpec` to `persistence.volumeClaimTemplate.spec`
- Updated the Service type of the proxy to be ClusterIP by default, see `proxy.service.type`
- And more, please refer to [values.yaml](values.yaml)

### New

- Added GraphDB and GraphDB proxy hostnames resolution in the init containers
- Added new annotation checksums for GraphDB and GraphDB proxy in order to detect changes in the properties configmaps
  and ultimately trigger rolling update
- Added default Secret objects for GraphDB and the proxy that contain sensitive GraphDB configurations
- Added `serviceAccount` configurations allowing you to create or use an existing service account for the GraphDB pods
- Added more feature toggles:
  - `headlessService.enabled`
  - `proxy.service.enabled`
  - `proxy.headlessService.enabled`
  - `persistence.enabled`
  - `proxy.persistence.enabled`
  - `cluster.jobs.createCluster.enabled` - Enables or disables the cluster creation Job
  - `cluster.jobs.patchCluster.enabled` - Enables or disables the Job for patching the cluster configuration
  - `cluster.jobs.scaleCluster.enabled` - Enables or disables the Jobs for scaling up or down the cluster
- Added `image.digest` to optionally provide an expected digest of the image
- Added `annotations` for additional common annotations across all resources
- Added separate `proxy.labels` and `proxy.annotations` configurations for the cluster proxy
- Added new `global.clusterDomain` for reconfiguring the default Kubernetes cluster domain suffix in case it is different than `cluster.local`
- Added `namespaceOverride` for overriding the deployment namespace for all resources in case of multi-namespace deployment
- Added new configuration options for the default ingress `ingress`:
  - Ability to override the `host` and `path` for GraphDB from `configuration.externalUrl`
  - Ability to change the Ingress path type with `ingress.pathType`
  - Inserting additional hosts and TLS configurations with `ingress.extraHosts` and `ingress.extraTLS`
- Added `security.admin` for configuring the initial password of the administrator user
- Added `security.initialUsers.users` for inserting additional users into the default initial user.js configuration
- Added `security.provisioner.existingSecret` and `security.provisioner.tokenKey` to provide an existing authentication token
- Added `cluster.token.existingSecret` and `cluster.token.secretKey` for using an existing Secret instead of providing the cluster secret
  token as plaintext in values.yaml
- Added `cluster.config.existingConfigmap` to specify a custom configmap key if needed
- Added `configuration.properties` and `proxy.configuration.properties` for appending additional inline GraphDB configurations in their properties
  configmaps
- Added `configuration.secretProperties` and `proxy.secretProperties` for appending additional inline sensitive GraphDB configurations if needed
- Added `configuration.extraProperties.existingConfigmap` and `proxy.configuration.extraProperties.existingConfigmap` for appending GraphDB properties
  from an existing ConfigMap resource
- Added `configuration.extraProperties.existingSecret` and `proxy.configuration.extraProperties.existingSecret` for appending GraphDB properties from
  an existing Secret resource
- Added a Service for single GraphDB deployments, configured with new configurations under `service`
- Added new configurations for the Service resources `service`, `headlessService`, `proxy.service` and `proxy.headlessService`:
  - Added `labels` configurations for insertion of additional labels
  - Added `ports` mappings in each Service
  - Added `extraPorts` for mapping additional ports, use in combination with `extraContainerPorts`
- Added `containerPorts` and `proxy.containerPorts` for mapping the ports on which GraphDB listens on
- Added `extraContainerPorts` and `proxy.extraContainerPorts` to open additional container ports
- Added `service.externalTrafficPolicy` and `service.proxy.externalTrafficPolicy` to override the policy to Local if needed
- Added `service.healthCheckNodePort` and `service.proxy.healthCheckNodePort` to define a specific node port for LB health checks
- Added `service.loadBalancerClass` and `service.proxy.loadBalancerClass` to select a specific load balancer implementation
- Added `service.loadBalancerSourceRanges` and `service.proxy.loadBalancerSourceRanges` to restrict the external ingress traffic from the LB
- Added `service.externalIPs` and `service.proxy.externalIPs` to use existing external IPs
- Added `persistence.emptyDir` and `proxy.persistence.emptyDir` configurations for an emptyDir volume that will be used when the persistence is
  disabled
- Added `tempVolume` configurations for an emptyDir volume mapped to the /tmp folder in the GraphDB containers
- Added configurations for extra `labels` and `annotations` for all persistent volume claim
  templates: `persistence.volumeClaimTemplate`, `proxy.persistence.volumeClaimTemplate` and `import.volumeMount.volumeClaimTemplate`
- Added `imagePullPolicy` configuration to the Jobs containers
- Added `jobs.backoffLimit` for configuring the retry count for all jobs
- Added `jobs.ttlSecondsAfterFinished` for configuring the time in seconds for all jobs before deleting finished pods
- Added `jobs.persistence.emptyDir` configurations for the default temporary storage for all jobs
- Added `proxy.command` and `proxy.args` that override the default container entrypoint and command, use for troubleshooting
- Added `proxy.pdb` for configuring a pod disruption budget for the GraphDB Proxy
- Added `proxy.logback` configurations for providing the proxy with a custom Logback XML configuration
- Added `proxy.initContainerSecurityContext` and `proxy.initContainerResources` to avoid using the configurations from GraphDB
- Added `automountServiceAccountToken` with default value `false` effectively ejecting the service account token by default
- Added `updateStrategy` and `proxy.updateStrategy` for controlling the strategy when updating pods
- Added `podManagementPolicy` and `proxy.podManagementPolicy` for configuring how the pods are created and scaled
- Added `schedulerName` and `proxy.schedulerName` for overriding the default Kubernetes scheduler
- Added `dnsConfig`, `dnsPolicy`, `proxy.dnsConfig` and `proxy.dnsPolicy` for customizing the DNS resolution if needed
- Added `extraContainers` and `proxy.extraContainers` for inserting additional containers into the pods of GraphDB and the GraphDB proxy
- Added `initContainerDataPermissions` and `proxy.initContainerDataPermissions` for changing permissions in the storage volumes if needed
- Added `extraVolumeClaimTemplates` and `proxy.extraVolumeClaimTemplates`
- Added `extraObjects` as a way to insert additional Kubernetes objects into the deployment
- Added `priorityClassName` and `proxy.priorityClassName` configurations

### Updates

- GraphDB and GraphDB proxy properties configmaps are now applied by default
- References to existing configmaps and secrets are now processed as templates
- Node scheduling configurations are now processed as templates
- Values in `labels`, `annotations` and `imagePullSecrets` are now evaluated as templates
- Removed unused busybox image configurations from `images.busybox`
- Renamed the port mappings of GraphDB and GraphDB proxy to `http` and `rpc`
- Service resources and probes now refer to the target ports by their nicknames instead of explicit port numbers
- Added trimming when loading files in the configmaps and secrets
- Cluster jobs now automatically resolve the cluster domain
- Removed `files/config/graphdb.properties` and `files/config/proxy/graphdb.properties` and moved any defined properties directly into the ConfigMap
  declarations
- Moved GraphDB specific properties from `GDB_JAVA_OPTS` into the properties ConfigMaps
- Added `-XX:-UseCompressedOops` in the default Java arguments to allow allocating heap sizes larger than 32GBs when the max heap size is based on
  the `-XX:MaxRAMPercentage` Java option
- Ejected the default service account token in the GraphDB proxy pods
- Overhauled NOTES.txt to be more helpful
- Added default resource limits and requests for all init containers and provisioning jobs
- PodDisruptionBudget are enabled by default for both GraphDB and GraphDB proxy
- Updated init containers to invoke `bash` instead of `sh`
- Updated the default memory limits and requests to 4Gi 

## Version 10.6.0-R2

### New

- Added `graphdb.node.extraInitContainers` and `graphdb.clusterProxy.extraInitContainers` that allows for the insertion of custom init containers to
  both GraphDB and its proxy
- Added `graphdb.clusterConfig.transactionLogMaximumSizeGB` configuration for the cluster creation JSON configuration.
- Added `graphdb.clusterConfig.existingClusterConfig` for providing a custom cluster creation JSON configuration.

### Fixed

- Fixed URLs in the [README.md](README.md) that refer to the official GraphDB documentation.
- Fixed the cluster creation JSON configuration to use `messageSizeKB` instead of `messageSize`, see `graphdb.clusterConfig.messageSize`.

## Version 10.6.0

### New

- Added `graphdb.node.licenseFilename` for cases where the default filename is not "graphdb.license"

### Improvements

- Updated the default ingress's path type to `ImplementationSpecific`
- Updated graphdb.properties example file
- Templates will now use `Chart.AppVersion` by default unless `images.graphdb.tag` is specified.
- Updated busybox image to version 1.36.1
- Use `clusterCreationTimeout` in patch cluster job as well

## Version 10.5.1-R2

- Fixed `graphdb-cluster-proxy-configmap` to use the correct java_args configuration from [values.yaml](values.yaml).

## Version 10.4.1

- Added configurations for specifying resource values for all remaining containers, see `graphdb.node.initContainerResources`
  and `graphdb.jobResources`.

## Version 10.3.1-R2

### Improvements

- Fixed the image registry to have priority over the global registry

## Version 10.3.0-R2

### New

- Added configurations for extra service annotations, see `graphdb.node.service.annotations`, `graphdb.clusterProxy.service.annotations`
  and `graphdb.clusterProxy.headlessService.annotations`

## Version 10.2.3

### New

- Added configurations for overriding graphdb-node's command and arguments, see `graphdb.node.command` and `graphdb.node.args`
- Added configurations for Pod Disruption Budget for the GraphDB nodes, see `graphdb.pdb`
- Added `graphdb-proxy-properties-configmap.yaml` to load graphdb.properties containing the cluster node addresses into the cluster-proxy

### Changed

- Removed `versions` field as it is not really used nor needed
- Removed the license provisioning init container in favor of directly mounting the license
- Removed unused `graphdb-node-storage` volume mount
- Removed the node addresses from the `graphdb-cluster-proxy-configmap.yaml` to prevent cluster proxy restarting on cluster scale up/down
- Updated the resources to not set CPU limits in order to avoid CPU throttling, lowered the default CPU requirements

## Version 10.2.2

### New

- Added configurations for extra env vars in the nodes and cluster proxies, see `graphdb.node.envFrom` and `graphdb.clusterProxy.extraEnv`.
- Added configurations for changing the `revisionHistoryLimit` for nodes and cluster proxies.
- Added configurations for adding extra `podLabels` and `podAnnotations` for both the nodes and cluster proxies.
- Added configurations for `terminationGracePeriodSeconds` to both the nodes and cluster proxies.
- Fixed an issue with setting the `provisioningUsername` to anything other than the default.

### Improvements

- Updated the templates to avoid rendering empty configurations
- Removed unused helper template `graphdbLicenseSecret`
- Added `graphdb` prefix in the helper templates function naming

## Version 10.2.1

### New

- Added configurable security context for both the node and cluster-proxy statefulsets and all the jobs
- Added extraEnv, extraVolumes and extraVolumeMounts to the statefulsets
- Added an optional PV/PVC to the cluster-proxy to properly preserve logs (enabled by default)
- Changed the provision user credentials to be used through a secret instead of rendering inside the jobs
- Changed the logback.xml and graphdb.properties provisioning to work even if such are already present
- Changed the graphdb-cluster-config-configmap map to not render when there is no cluster
- Changed the default values of nodeSelector, affinity, tolerations and topologySpreadConstraints to be a part of the values.yaml file
  instead of inside the statefulsets
- Updated default clusterConfig.electionMinTimeout and clusterConfig.electionRangeTimeout to the current GraphDB defaults
- Updated the cluster proxy probes settings, so it can become available sooner
- Updated the cluster and repositories jobs with simpler arguments removing the need to copy scripts and to make them executable
- Added ephemeral volumes in the cluster and repositories jobs to avoid issues with readonly file systems

## Version 10.2.0-R2

### New

- Added the ability to provision a repository

## Version 10.1.5-R2

### New

- Fixed an issue with the external proxy connecting to the nodes when https is used

## Version 10.1.2-R2

### New

- Added ability to override cluster proxy's type, default remains LoadBalancer

## Version 10.1.1-R2

### New

- Fixed ingress template to properly handle root context
- Fixed single node returning wrong location header with explicit transactions

## Version 10.0.1

### Breaking

- The graphdb-node service now is always headless. If you installed Version 10.0.0 with `graphdb.clusterConfig.nodesCount` set to `1` you
  will have to delete the service prior to an update

### New

- Upgrade to GraphDB 10.0.1
- Cluster size can now be scaled
- Fixed an issue with deploying with security turned on
- Fixed an issue with the cluster proxy returning its internal address when queried externally

## Version 10.0.0

### Breaking

New major release that isn't compatible with the old chart, due to major breaking changes in Graphdb 10. Migration steps can be found
[here](README.md#cluster-migration-from-graphdb-9x-to-100).

### New

- Changed to work with the new GraphDB 10.
- Removed Kong.
- Moved from multiple stateful sets with 1 replica to statefulsets with multiple replicas.
- Configurable liveness, readiness, startup probes.
- Can use standalone without license by default. Don't forget to set your license for a working cluster and connectors!
- New overridable configmaps for users, settings and logback.

## Version 9.9.0

### Breaking

- `images.graphdb`, `images.kong` and `images.busybox` are now maps which can specify `registry`, `repository` and `tag`

### New

- Added global variables support (global.deployment.host/global.ingressHost, global.storageClass, global.imagePullSecrets and
  global.imageRegistry)
- Add ability to override logback.xml by setting `deplyment.logbackConfigFile` to the location of the file to use
- Set additional JMX attributes using `graphdb.masters.additionalJmxArrtibutes`. This is a map of attr_name=attr_value pairs
- Fixed loadrdf tool path
- Moved to dynamic volume provisioning by default (volumeClaimTemplates), old default pvc/pv's are still available
- Added JDBC driver support for Ontop functionality
- Minor fixes

## Version 9.8.1

### New

- Added multiple repositories provisioning
- Added security provisioning
- Added GraphDB properties provisioning
- Changed GraphDB vhosts and external url properties
- Upgrade to GraphDB 9.8.1
- Provide flexible persistence provisioning
- Provide HA options like node selectors, podaffinity, tolerations, etc
- Make Ingress and kong optional
- Minor fixes
