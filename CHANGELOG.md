# GraphDB Helm chart release notes

## Version 9.9.0

### Breaking

- `images.graphdb`, `images.kong` and `images.busybox` are now maps which can specify `registry`, `repository` and `tag`

### New

- Added global variables support (global.deployment.host/global.ingressHost, global.storageClass, global.imagePullSecrets and global.imageRegistry)
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
