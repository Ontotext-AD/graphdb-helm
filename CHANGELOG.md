# GraphDB Helm chart release notes

## Version 11.0.0

TODO: short motivational paragraph about the major version
TODO: short info about being decoupled from GraphDB
TODO: short section about the most notable changes (decoupling, naming, plugins, etc.)

### Breaking

TODO: decide how detailed we want this to be

- Resource names are no longer hardcoded and are using the templates for `nameOverride` and `fullnameOverride`
- Renamed `extraLabels` to just `labels`
- Renamed GraphDB storage PVC prefix to `graphdb-storage` and server import folder to `graphdb-server-import`
- Removed setting FQDN as hostnames in GraphDB and the proxy in favor of dynamically resolving and configuring the hostnames in the init containers
- Renamed `messageSize` to `messageSizeKB` in the cluster creation configuration
- Renamed `java_args` to `javaArguments`
- Removed the default logback XML configuration and configmap in favor of an [example](examples/custom-logback) and a new configuration options
  under `logging.logback`
- Removed `global.storageClass` in favor of using by default the default storage class in the cluster. Templates will no longer
  use `global.storageClass`.
- Updated the GraphDB deployment URL to be http://graphdb.127.0.0.1.nip.io/ by default
- Removed the default value from `global.imageRegistry`, the chart now uses the value from `image.registry`
- Updated the ingress to be agnostic to the ingress implementation. It will no longer assume that NGINX is the ingress controller in the
  cluster and will no longer deploy NGINX specific annotations by default. Removed anything related to NGINX as configurations.
- Moved all proxy configurations from `graphdb.clusterProxy` to just `proxy`
  - Renamed `proxy.persistence.enablePersistence` toggle to just `enabled`
  - Moved `proxy.serviceType` to `proxy.service.type`
- Configmaps from `graphdb.configs` are now under `extraConfiguration`, `repositories` and `initialConfiguration` with a different structure allowing
  better reuse of existing configmaps
  - Users are now provided as a Secret
- Moved job related configurations from `graphdb` (e.g. `graphdb.jobResources`) to a new root section `jobs`
- Moved `images.graphdb` configurations to just `image`
- Moved `deployment.imagePullPolicy` to `image.pullPolicy` and `deployment.imagePullSecret` to `image.pullSecrets`
  - Updated `imagePullSecret` to be a list, e.g. `imagePullSecrets`
- Moved `graphdb.import_directory_mount` configurations to `import.volumeMount`
- Moved `deployment.ingress` to just `ingress`
  - Moved `deployment.tls` to `ingress.tls`
- Renamed `graphdb.node.service` to `headlessService`
- Moved `graphdb` and `graphdb.node` configurations on the root level
  - Moved `graphdb.pdb` to `pdb`
- Moved `graphdb.clusterConfig` configurations
  - Moved `graphdb.clusterConfig.nodesCount` to `replicas`
  - Moved the rest of `graphdb.clusterConfig` configurations under `cluster` and `cluster.config`
- Moved `graphdb.security` configurations to `security`
- Updated the Service type of the proxy to be ClusterIP by default

### New

- Added `annotations` for common annotations across resources
- Added `serviceAccount` allowing you to create or use an existing service account for GraphDB pods
- Added separate `labels` and `annotations` for the cluster proxy
- Added GraphDB and GraphDB proxy hostnames resolution in the init containers
- Added `conpfiguration.properties` and `proxy.configuration.properties` for inserting additional GraphDB configurations in the properties configmaps
- Added `image.sha` to optionally provide an expected SHA checksum of the image
- Added `persistence.enabled` toggle flag for enabling or disabling the persistence of GraphDB
- Added new configuration options for the default ingress `ingress`:
  - Ability to override the `host` and `path` for GraphDB from `configuration.host` and `configuration.path`
  - Changing the `pathType`
  - Inserting additional hosts and TLS configurations with `extraHosts` and `extraTLS`
- Added `labels` for each service resource for insertion of additional labels
- Added `containerPorts` and `proxy.containerPorts` for mapping the ports on which GraphDB listens on
- Added `ports` mappings in each service
- Added `extraContainerPorts` and `proxy.extraContainerPorts`
- Added `imagePullPolicy` to the jobs containers
- Added feature toggles
  - `cluster.jobs.createCluster.enabled`
  - `cluster.jobs.patchCluster.enabled`
  - `cluster.jobs.scaleCluster.enabled`
  - `headlessService.enabled`
  - `proxy.service.enabled`
  - `proxy.headlessService.enabled`
- Added new annotation checksums for GraphDB and GraphDB proxy in order to detect changes in the properties configmaps 
  and ultimately trigger rolling update
- Added a Service for single GraphDB deployments, configured with new configurations under `service`
- Added new proxy configurations `proxy.command` and `proxy.args` that override the default container entrypoint and command, use for troubleshooting
- Added new `global.clusterDomain` for reconfiguring the default Kubernetes cluster domain suffix in case it is different than `cluster.local`
- Added `cluster.existingConfigmapKey` to specify a custom configmap key if needed
- Added `namespaceOverride` for overriding the deployment namespace for all resources in case of multi-namespace deployment
- Added `proxy.logging.logback` configurations for providing the proxy with a custom Logback XML configuration

### Updates

- GraphDB properties configmap is now applied by default
- Values in `labels`, `annotations` and `imagePullSecrets` are now evaluated as templates
- Removed unused busybox image configurations from `images.busybox`
- Service resources and probes now refer to the target ports by their nicknames
- Renamed the port mappings of GraphDB and GraphDB proxy to `http` and `rpc`
- References to existing configmaps and secrets are now processed as templates
- Added trimming when loading files in the configmaps and secrets
- Cluster jobs now automatically resolves the cluster domain
- Moved `files/config/proxy/graphdb.properties` to [files/config/graphdb-proxy.properties](./files/config/graphdb-proxy.properties)

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
