# GraphDB Helm chart release notes

## Version 9.9.0

### New

- Added global variables support (global.deployment.host)
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
