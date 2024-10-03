# GraphDB External Plugins Examples

This folder contains examples of how to configure GraphDB with external plugins by providing them to the classpath.
See https://graphdb.ontotext.com/documentation/10.7/plug-in-api.html#adding-external-plugins-to-graphdb for more information and
configuration examples.

## Using GraphDB Persistence

For GraphDB to pick up and use external plugins, their JAR files must be registered in the classpath.
The Helm chart configures GraphDB to expect extra plugins at `/opt/graphdb/home/extra-plugins` from where the database will pick them up.

The directory `/opt/graphdb/home/extra-plugins` is located inside the default persistence volume.
Any extra plugins that have been provisioned in this directory will be available between pod restarts and GraphDB updates.

There are two common ways to provide extra plugins inside existing PV:

* Using a custom init container that will download JARs from the internet or from other locations.
* Copying the files manually using `kubectl` from your local system or copying them from another PV.

This example will focus on copying JAR files with `kubectl`.

For example, to configure GraphDB with an external plugin inside the GraphDB pod `graphdb-0`, you can use:

```bash
kubectl cp custom-plugin.jar graphdb-0:/opt/graphdb/home/extra-plugins/
```

In case of a GraphDB cluster setup, you have to provide the plugin to all pods:

```bash
kubectl cp custom-plugin.jar graphdb-0:/opt/graphdb/home/extra-plugins/
kubectl cp custom-plugin.jar graphdb-1:/opt/graphdb/home/extra-plugins/
kubectl cp custom-plugin.jar graphdb-2:/opt/graphdb/home/extra-plugins/
```

## Using Another Persistence Volume

Another option is to prepare a different PVC and PV, copy the plugins inside that PV and configure GraphDB to use it with:

```yaml
extraVolumes:
  - name: extra-plugins
    persistentVolumeClaim:
      claimName: graphdb-extra-plugins

extraVolumeMounts:
  - name: extra-plugins
    mountPath: /opt/graphdb/home/extra-plugins
```
