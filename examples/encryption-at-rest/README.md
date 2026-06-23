# Encryption at Rest examples for GraphDB

This example shows how to configure the Helm chart with encryption at rest. Two alternatives are currently supported:
- Using a master key file
- Using a keystore that contains the master key

## Requirements

For PKCS12 configuration (i.e. keystore), you need `keytool` to create the `p12` keystore file.

## Configuring Encryption at Rest with a master key file

First, create the master key. The example below uses a SHA256-generated digest using `openssl`

```bash
openssl dgst -sha256 -binary <path-to-local-file> > master.key
```

Then, create the secret, and install the helm chart

```bash
kubectl create secret generic graphdb-masterkey --from-file=masterKey=master.key
helm install --values enc-file-values.yaml graphdb ontotext/graphdb
```

## Configuring Encryption at Rest with a keystore (PKCS12)

First, create the keystore. For this, you need `keytool`

```bash
keytool -genseckey -alias masterkey -keyalg AES -keysize 256 -keystore master.p12 -storetype PKCS12 -storepass password -keypass password
```

Then, upload the keystore and the keystore password as kubectl secrets and install the helm chart

```bash
kubectl create secret generic graphdb-masterkeystore --from-file=masterKeyStore=master.p12
kubectl create secret generic graphdb-masterkeystorePassword --from-listeral=masterkeystorePassword=password
helm install --values enc-pkcs12-values.yaml graphdb ontotext/graphdb
```
