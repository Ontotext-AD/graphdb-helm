# GraphDB Helm Chart Upgrade Guide

## From 11.x to 12

This major version has no particular breaking changes. Nevertheless, it is highly recommended to perform a backup before upgrading existing
deployments to the next major version. Please, follow the official backup procedure
at https://graphdb.ontotext.com/documentation/10.8/backup-and-restore.html.

## From 10.x to 11

Before continuing, familiarize yourself with the new configuration structure in [values.yaml](values.yaml) as well as with
the [changelog for version 11](CHANGELOG.md#version-1100).

### Configurations

Version 11 of the Helm chart introduces a lot of changes to the configurations and their structure in [values.yaml](values.yaml).
Here are the most notable steps that you should be aware of:

**Kubernetes Version**

The Helm chart is updated to require a minimum Kubernetes version of 1.26.
Refer to the official Kubernetes documentation on how to move to a newer version if needed.
We strongly advise to operate a Kubernetes cluster with version that has not reached its End Of Life.

**Naming**

The resource names are no longer hardcoded in version 11. If you want to keep the old ones, you can override the following configurations from
[values.yaml](values.yaml): `fullnameOverride` and `proxy.fullnameOverride`.

**GraphDB URL**

The old version 10 of the chart had several configuration properties that defined the external URL of GraphDB: `deployment.protocol`,
`deployment.host` and `graphdb.workbench.subpath`.
In version 11, they have been combined into a single configuration property `configuration.externalUrl`.
Make sure to update it accordingly.

Note that the default URL configuration now uses https://nip.io/ which avoids having to edit your hosts file, compared to version 10.
However, this is suitable only for local development, so you'd have to update it to a real resolvable URL according to your environment and
requirements.

**Ingress**

If you use the Ingress for accessing GraphDB: Version 11 removes the default use of specific ingress controllers.
It's up to you to properly set up the default ingress controller in your cluster or to properly configure the default Ingress in this chart with
the `ingress` configuration in [values.yaml](values.yaml).

For configuring the Ingress to work with the NGINX controller, you can check the examples in [examples/ingress-nginx/](examples/ingress-nginx) folder.

**Storage Class**

Version 11 removes the hardcoded storage class from `global.storageClass`.
If you don't have a default storage class in your cluster, you can define the storage class for GraphDB's PVC
with `persistence.volumeClaimTemplate.spec.storageClassName` for GraphDB and `persistence.volumeClaimTemplate.spec.storageClassName` for the proxy (if
enabled).

**Persistence**

Persistence configurations from `graphdb.node.persistence` have been moved to `persistence` and `graphdb.clusterProxy.persitence`
to `proxy.persistence`.

**Cluster**

Version 11 now uses `replicas` instead of `graphdb.clusterConfig.nodesCount` to control the deployment of GraphDB proxies and the creation of the
cluster.

Note that all other cluster related configurations have been moved under the `cluster` section in [values.yaml](values.yaml).

**Security**

Note that all security configurations have been moved under the `security` section in [values.yaml](values.yaml).

The provisioning user credentials are now under `security.provisioner`.

**Other**

See [11.0.0 Breaking Changes section](./CHANGELOG.md) for more details on migrating other configurations.

### Data Migration

Due to the amount of breaking changes in version 11, any volumes created by version 10 won't be reused automatically.
Here are two options to migrate GraphDB data for version 11, each of which require some downtime.

**Backup and Restore**

Probably the easiest migration option is to use GraphDB's own
[backup and restore](https://graphdb.ontotext.com/documentation/10.6/backup-and-restore.html) functionality.

1. Follow GraphDB's documentation on how to trigger a Backup, you can choose:
   - [Local backup](https://graphdb.ontotext.com/documentation/10.6/backup-and-restore.html#creating-a-backup)
   - [Cloud backup](https://graphdb.ontotext.com/documentation/10.6/backup-and-restore.html#creating-and-restoring-cloud-backups)
2. Uninstall the old deployment. Note that this won't remove your existing PVs.
3. Install the new version of the Helm chart
4. Use the restore operation:
   - Restore from [local backup](https://graphdb.ontotext.com/documentation/10.6/backup-and-restore.html#restoring-from-a-backup)
   - Restore from [cloud backup](https://graphdb.ontotext.com/documentation/10.6/backup-and-restore.html#restoring-from-a-cloud-backup)

The downside of this option is that if there are a lot of GBs of data to be backed up and later restored, this option would be the slowest.

**Matching PVC claims**

To minimize the downtime from **Backup and Restore**, you could reuse the existing Persistent Volumes from the deployment made with version 10 of
the chart. The procedure is as follows:

1. Make note of the names of the existing PVs and PVCs:
   - Kubernetes uses the following policy for naming PVC: `<pvc-template-name>-<statefulset-name>-<pod index>`, i.e. this would be
    `graphdb-node-data-dynamic-pvc-graphdb-node-0` for version 10 of the chart.
   - For the new version 11, this depends on the release name or if you'll use name overrides, but it should be something like this:
    `storage-<statefulset-name>-<pod-index>`, i.e. `storage-test-graphdb-0` where `test` is the Helm release name.
2. Uninstall the old deployment with `helm uninstall ...`
3. Make sure that the reclaim policy of the existing PVs is set to `Retain`. For each PVC, find the corresponding PV and patch it with:
   ```bash
   kubectl patch pv <pv-name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
   ```
   where:
   - `pv-name` is the name of one of the existing persistent volumes
4. Patch the existing PVs with `"claimRef":null` to force them to go from status `Released` to `Available`, use:
   ```bash
   kubectl patch pv <pv-name> -p '{"spec":{"claimRef":null}}'
   ```
   where:
   * `pv-name` is the name of one of the existing persistent volumes
5. Update the existing PVs `claimRef` attribute to match the PVC names that will be created by the new PVC template in version 11, use:
   ```bash
   kubectl patch pv <pv-name> -p '{"spec":{"claimRef":{"name":"storage-<statefulset-name>-<pod-index>","namespace":"<namespace>"}}}'
   ```
   where:
   * `pv-name` is the name of one of the existing persistent volumes
   * `statefulset-name` is the name of the StatefulSet for GraphDB, and it depends on the release name or any name overrides
   * `pod-index` is the ordinal index of a concrete pod, i.e. `0`, `1` and `2` for a 3 node cluster
   * `namespace` is the Kubernetes namespace where you'll deploy the Helm chart

   If you are not fully sure what are the correct PVCs names, you could first deploy the new version to make note of the PVC naming and patch the
   PVs later.

The downside of this option is that the user that owns the data in the existing PVs is `root` while the new chart runs with a non-root user.
[Fixing Permissions](#fixing-permissions) explains further.

#### Fixing Permissions

Version 11 of the chart includes a default security context that avoids running containers with the `root` user.
However, version 10 of the chart have been running containers with the `root` user.
This requires changing ownership of the data when using existing Persistent Volumes.

Note that if you've selected to use the **Backup and Restore** option for the data migration, these next steps are not needed.

There are 3 options that you can choose from:

**Using an initContainer**

The chart includes a special init container that will change the data to be owned by the configured user in the security context.
Set `initContainerDataPermissions.enabled` to `true` to enable it for GraphDB and `proxy.initContainerDataPermissions.enabled` to `true` for the
proxies. This should be a one time operation, so you can disable them later.

You can also provide a custom init container with `extraInitContainers` and `proxy.extraInitContainers`

**Reconfigure the context**

Alternatively, you can reconfigure the security context configurations to use the `root` user.
This includes the following configurations:

* `podSecurityContext`, `securityContext` and `initContainerSecurityContext` for GraphDB
* `proxy.podSecurityContext`, `proxy.securityContext` and `proxy.initContainerSecurityContext` for the GraphDB proxies
* `jobs.podSecurityContext` and `jobs.securityContext` for the cluster management Jobs

**Manually**

You could mount the persistent volumes to temporary pods and manually update the permissions.
The process is similar to matching PVC claims as described above but to pods that would just update the ownership of the data.

Consider this option if you would like to avoid the init container approach.

---

You can now install the new Helm chart version.

## From 9.x to 10

**Warning**: Before starting the migration change your master into read only mode.
The process is irreversible and full backup is HIGHLY advisable.
At minimum backup the PV of the worker you are planing to use for migration.

The Helm chart is completely new and not backwards-compatible.

1. Make all masters read only, you can use the workbench.

2. Using the workbench disconnect all repositories of the worker which we are going to use to migrate to 10.0.
   If you've used the official GraphDB helm chart you can select any worker.
   In case of a custom implementation select one that can easily be scaled down.

   **Note**: Only the repositories that are on the worker will be migrated into the new cluster!

3. Get the PV information of the worker, noting down the capacity and the access mode:
   ```bash
   kubectl get pv
   ```

4. Note down the resource limits of the worker node:
   ```bash
   kubectl get pod graphdb-worker-<selected-worker> -o yaml | grep -B 2 memory
   ```

5. Make sure all the important settings saved in the settings.js of the master are present in the workers. Their only difference
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

7. Scale down the selected worker. In the official GraphDB chart, every worker has its own statefulset.
   List all the stateful sets to find the name of the worker you want to scale down:
   ```bash
   kubectl get statefulsets
   ```
   Then change the number of replicas to 0:
   ```bash
   kubectl scale statefulsets <stateful-set-name> --replicas=0
   ```

8. Once the worker is down, patch the worker's PV with `"persistentVolumeReclaimPolicy":"Retain"`:
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
