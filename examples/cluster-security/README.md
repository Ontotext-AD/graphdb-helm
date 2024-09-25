# TLS authentication examples

This folder contains examples of configuring and deploying GraphDB with cluster security(TLS) enabled.

The examples show how to configure raft cluster security using existing certificate and private key/existing keystore 
with the default java truststore. 

## References

* [GraphDB official documentation](https://graphdb.ontotext.com/documentation/10.7/)
* [Raft security configurations](https://graphdb.ontotext.com/documentation/10.7/directories-and-config-properties.html#cluster-properties)

## Prerequisites
* Self-signed certificate and private key. Since we are using a shared certificate for all nodes it must 
be issued to the domains of all nodes using a wildcard ex *.graphdb-headless.default.svc.cluster.local 
or specify the domain of each node explicitly(graphdb-0.graphdb-headless.default.svc.cluster.local, etc., as SAN entries).
* Keystore(if you are using this approach) that contains both the certificate and the private key
* Add your certificate to the default java trust store

## Usage
1. Customize [secrets](secrets) according to your needs and apply:

   ```bash
   kubectl apply --filename secrets/ --recursive
   ```
2. Configure the Helm chart to use the secrets in [values_existing_certificate.yaml](values_existing_certificate.yaml)
and [values_existing_keystore.yaml](values_existing_keystore.yaml)
   ```yaml
   extraVolumes:
     - name: my-volume
       secret:
         secretName: my-secret 
   extraVolumeMounts:
     - name: my-volume
       mountPath: /opt/graphdb/home/myasset 
       subPath: myasset 
   ```
3. Apply the configurations.
   ```bash
   helm install graphdb ontotext/graphdb -f values.yaml 
   ```
## Example
* [values_existing_certificate.yaml](values_existing_certificate.yaml) - Example of how to configure cluster security in GraphDB with existing certificate and private key
* [values_existing_keystore.yaml](values_existing_keystore.yaml) - Example of how to configure cluster security in GraphDB with existing keystore 

## Note
* The above examples use a single self-signed certificate that is shared across all nodes since configuring 
a separate certificate for each node is possible but introduces a lot of configuration overhead. For more information
see https://graphdb.ontotext.com/documentation/10.7/encryption.html#use-self-signed-certificates
