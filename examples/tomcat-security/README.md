Configuring Tomcat server with SSL/TLS
===

This guide provides instructions for configuring the embedded GraphDB Tomcat server with SSL/TLS.
There are 3 scenarios for configuring the security of the GraphDB instance:
- By providing a keystore.
- By providing keystore and truststore - used to configure mTLS.
- By providing a truststore - used in cases where GraphDB should trust an external service.

**Note**
If the Tomcat server is configured with SSL/TLS it will also configure the cluster gRPC communication SSL/TLS.

### See more about Tomcat TLS/SSL set up:
- GraphDB official documentation: https://graphdb.ontotext.com/documentation/10.8/encryption.html#configuring-graphdb-instance-with-ssl
- Tomcat documentation: https://tomcat.apache.org/tomcat-9.0-doc/ssl-howto.html
- Troubleshooting: https://tomcat.apache.org/tomcat-7.0-doc/ssl-howto.html#Troubleshooting

## Configuring using keystore and truststore 

**Prerequisites:**
* Certificate and certificate private key in PEM format.
* Keystore that contains both the private key and certificate.
* Truststore that contains the certificate to be trusted or the CA.

[Configuration example](keystoreAndTruststore.yaml)

## Configuring using keystore

**Prerequisites:**
* Keystore that contains both the private key and certificate.

[Configuration example](keystore.yaml)

## Configuring using truststore

**Prerequisites:**
* Truststore that contains the certificate to be trusted or the CA.

[Configuration example](truststore.yaml)
