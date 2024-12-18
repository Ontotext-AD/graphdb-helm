Configuring cluster gRPC communication with SSL/TLS
===

This guide provides instructions for configuring GraphDB cluster gRPC communication with SSL/TLS. It details how to 
configure it:
* Using JSSE: By providing keystore and truststore.
* Using OpenSSL: By providing certificate file, certificate chain, private key and truststore.
* Using a certificate without chain path: By providing certificate file, private key and truststore.  

**Note:**  
The message that indicates that the gRPC cluster security has been set up is logged at DEBUG level so your Logger 
should be configured accordingly.
### See more about TLS/SSL set up:
 - GraphDB configuration properties : https://graphdb.ontotext.com/documentation/10.8/directories-and-config-properties.html#cluster-properties
 - Tomcat documentation: https://tomcat.apache.org/tomcat-9.0-doc/ssl-howto.html
 - Troubleshooting: https://tomcat.apache.org/tomcat-7.0-doc/ssl-howto.html#Troubleshooting

## Warning

If cluster.tls.mode is set to TLS while one or more of the other TLS-related properties are not configured properly, 
the server may not be able to start.

## Configuring using JSSE

**Prerequisites:**
* Certificate and certificate private key in PEM format
* Keystore that contains both the private key and certificate
* Truststore that contains the certificate to be trusted or the CA

[Configuration example](jsse.yaml) 

## Configuring using OpenSSL

**Prerequisites:**
* Certificate and certificate private key in PEM format
* Valid certificate chain that contains the target certificate
* Truststore that contains the certificate to be trusted or the CA

[Configuration example](openssl.yaml) 

## Configuring using certificate without certificate chain

**Prerequisites:**
* Certificate and certificate private key in PEM format.
* Truststore that contains the certificate to be trusted or the CA

[Configuration example](certWithoutChain.yaml)  

