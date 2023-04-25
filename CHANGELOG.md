# GraphDB Helm chart release notes

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
