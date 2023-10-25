# GraphDB Helm chart release notes

## Version 10.6.0

- Updated the default ingress's path type to `ImplementationSpecific`

## Version 10.5.1-R2

- Fixed `graphdb-cluster-proxy-configmap` to use the correct java_args configuration from [values.yaml](values.yaml).

## Version 10.4.1

- Added configurations for specifying resource values for all remaining containers, see `graphdb.node.initContainerResources` and `graphdb.jobResources`.

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
