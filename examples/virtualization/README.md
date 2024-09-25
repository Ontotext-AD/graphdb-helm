# GraphDB Virtualization Examples

This folder contains examples of how to configure GraphDB's virtualization features by providing JDBC drivers to GraphDB's classpath.
See https://graphdb.ontotext.com/documentation/10.7/virtualization.html for more information and [Ontop](https://ontop-vkg.org/guide/)
configuration examples.

## Using GraphDB Persistence

For GraphDB to pick up and use JDBC drivers, their JAR files must be registered in the classpath.
The Helm chart configures GraphDB to expect JDBC drivers at `/opt/graphdb/home/jdbc-driver` from where the database will pick them up.
This detection is dynamic so you don't need to restart GraphDB when provisioning drivers.

The directory `/opt/graphdb/home/jdbc-driver` is located inside the default persistence volume.
JDBC drivers that have been provisioned in this directory will be available between pod restarts and GraphDB updates.

There are two common ways to provide drivers inside existing PV:

* Using a custom init container that will download JDBC jars from the internet.
* Copying the files manually using `kubectl` or from another PV.

This example will focus on copying JAR files with `kubectl`.

For example, to configure GraphDB with a JDBC driver for PostgreSQL inside the GraphDB pod `graphdb-0`, you can use:

```bash
kubectl cp postgresql-42.7.4.jar graphdb-0:/opt/graphdb/home/jdbc-driver/
```

In case of a GraphDB cluster setup, you have to provide the driver to all pods:

```bash
kubectl cp postgresql-42.7.4.jar graphdb-0:/opt/graphdb/home/jdbc-driver/
kubectl cp postgresql-42.7.4.jar graphdb-1:/opt/graphdb/home/jdbc-driver/
kubectl cp postgresql-42.7.4.jar graphdb-2:/opt/graphdb/home/jdbc-driver/
```

## Using Another Persistence Volume

Another option is to prepare a different PVC and PV, copy the JDBC drivers inside that PV and configure GraphDB to use this with:

```yaml
extraVolumes:
  - name: jdbc-drivers
    persistentVolumeClaim:
      claimName: jdbc-drivers

extraVolumeMounts:
  - name: jdbc-drivers
    mountPath: /opt/graphdb/home/jdbc-driver
```
