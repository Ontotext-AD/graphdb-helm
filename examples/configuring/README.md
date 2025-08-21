Configuring GraphDB
===

This document provides detailed instructions on how to configure GraphDB,
including setting properties, secret properties, and additional configurations.

It covers various methods to manage configuration options, such as using
ConfigMaps and Secrets, and highlights some good practices to ensure secure
and efficient setup. Additionally, it explains how to set Java arguments
and environment variables for GraphDB.

All GraphDB configuration options can be found
[here](https://graphdb.ontotext.com/documentation/11.1/directories-and-config-properties.html#general-properties).

## Properties

This section is used to set GraphDB properties in the default ConfigMap for
graphdb.properties directly from the `values.yaml` file.
The configurations, typically including non-sensitive information such as product settings,
will be merged with the properties in the default ConfigMap.

```yaml
configuration:
  properties:
    graphdb.workbench.importDirectory: "/opt/graphdb/home/graphdb-import"
    graphdb.cluster.sync.timeoutS: 600
    graphdb.workbench.maxConnections: 10
```

## Secret Properties

This section is used to set default Secret properties directly from the `values.yaml` file.
The configurations, typically including sensitive information such as secret tokens (eg. OpenAI API tokens),
will be merged with the properties in the default Secret.

```yaml
configuration:
  secretProperties:
    graphdb.connector.keystorePass: "xxxx"
```

**Warning: This method of configuring GraphDB is strongly discouraged, as it may
lead to secrets being exposed or stored insecurely!**

## Extra Properties

This section explains how to configure extra properties for GraphDB using
an existing Kubernetes ConfigMap or an existing Secret. The resources mentioned in
this section can be found in the [resources.yaml](./resources.yaml) file.

The appropriate resources are used for each specific case.

The chart expects these to contain a key, specified by `configmapKey` or
`secretKey` for the Secret resource, with a default of graphdb.properties.
The content of this key will be merged with the content of the default ConfigMap and Secret.

### Using existing ConfigMap

```yaml
configuration:
  extraProperties:
    existingConfigmap: custom-graphdb-properties
    # configmapKey: graphdb.properties   # Default key
```

### Using existing Secret

```yaml
configuration:
  extraProperties:
    existingSecret: custom-graphdb-secret-properties
    secretKey: graphdb-secrets.properties
```

## Java Arguments

This section explains how to set Java arguments for GraphDB using
the `values.yaml` file. The `configuration.javaArguments` field allows you to specify
Java Virtual Machine (JVM) options, such as memory settings, to optimize
the performance and resource usage of the GraphDB instance.

It also supports GraphDB properties in the form of `-Dproperty=value`

```yaml
configuration:
  javaArguments: "-Xms4G -Xmx4G -Dgraphdb.external-url=example.com"
```

## Extra Environment Variables from a source

This section explains how to configure GraphDB with environment variables
using an existing Kubernetes ConfigMap or an existing Secrets. This approach
ensures that additional configurations are injected alongside existing
ones without mixing different contexts.

The resources referenced in this section can be found in the [resources.yaml](./resources.yaml) file.

```yaml
extraEnvFrom:
  - configMapRef:
      name: "connector-properties"
  - secretRef:
      name: "connector-secret-properties"
```

## Extra Environment Variables

This section demonstrates how environment variables can be directly set up in the Helm
chart's `values.yaml` file, eliminating the need to configure them separately in a ConfigMap or Secret.

```yaml
extraEnv:
  - name: "graphdb.workbench.importDirectory"
    value: "/opt/graphdb/home/graphdb-import"
```

## Final words

The most recommended way of configuration GraphDB is by using existing resources, especially for
the sensitive information. In this cases `configuration.extraProperties` and `extraEnvFrom`
are most suitable for this.

For non-sensitive information any method of configuring GraphDB is viable.
