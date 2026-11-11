# Cert-Manager Examples

This example shows how to configure GraphDB to use a self-signed certificate issued from http://cert-manager.io/.
This certificate can be used for configuring Tomcat's SSL connector as well as for the gRPC communication in GraphDB
between cluster nodes and proxies.

## Certificates

You have two options depending on your deployment.

Option 1: Standalone GraphDB (no cluster):

```shell
kubectl apply -f ./cert-manager-tls.yaml
```

Option 2: GraphDB cluster

```shell
kubectl apply -f ./cert-manager-tls-cluster.yaml
```

## Configurations

After creating the certificate, you can use it with:

```yaml
configuration:
  tls:
    keystore:
      existingSecret: graphdb-tls
      keystoreKey: keystore.p12
      keystorePasswordSecret: graphdb-keystore-password
      keystorePasswordKey: password
      keystoreType: PKCS12
      keyAlias: 1
```

See [values.yaml](values.yaml).
