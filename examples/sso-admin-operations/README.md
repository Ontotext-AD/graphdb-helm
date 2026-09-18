Performing administrative operations with SSO
===

This guide provides instructions for performing administrative operations in a system with basic auth disabled and SSO
(OIDC+OAuth) enabled.

## Setup

For the purpose of this guide, you need to have a IDP with a machine-to-machine workflow enabled. The example has been
tested with Azure Entra ID. Quick guide for Azure:
1. Create an Entra ID app registration.
2. Create a Single-Page application.
3. Add the email claim under Token configuration.
4. Expose an API.
5. Add the GDB_ROLE_ADMIN and GDB_ROLE_USER app roles.
6. Edit the manifest so `requestedAccessTokenVersion` = 2 and `acceptMappedClaims` = true
7. Go to your enterprise application (it is created automatically and mapped to your app registration)
8. Under SSO, add an attribute claim called `graphdb_username`. The Transformation should be: "If the user.mail"
   attribute is empty, set it to Automation. Else, provide it as an output."
9. Go back to Entra ID app registrations and create a new one.
10. Create a new secret.
11. Grant API permissions to the previously created app registration from step 1. They should have the GDB_ROLE_ADMIN role.

You should store the following values:
* Your tenant ID.
* The client ID of the app registration for GDB created in step 1.
* The client ID of the app registration for Automation created in step 9.
* The secret of the app registration for Automation created in step 10.

These values should be used to populate a secret:
```bash
kubectl create secret generic gdb-sso \
 --from-literal=clientId=<M2M_CLIENT_ID> \
 --from-literal=clientSecret=<M2M_CLIENT_SECRET> \
 --from-literal=tokenUrl=https://login.microsoftonline.com/<TENANT_ID>/oauth2/v2.0/token \
 --from-literal=scopesKey=api://<GDB_CLIENT_ID>/.default
```
Now you should be able to set up the Automation (m2m) app registration and also the GDB app registration.

## Configuring GDB security

This section shows how to configure GraphDB for SSO.

```yaml
configuration:
  externalUrl: https://graphdb.apps-crc.testing
  properties:
    graphdb.auth.security.enabled: "true"
    graphdb.auth.methods: "openid"
    graphdb.auth.openid.issuer: "https://login.microsoftonline.com/<TENANT_ID>/v2.0"
    graphdb.auth.openid.client_id: "<GDB_CLIENT_ID>"
    graphdb.auth.openid.username_claim: "email"
    graphdb.auth.openid.auth_flow: "code"
    graphdb.auth.openid.token_type: "access"
    graphdb.auth.database: "oauth"
    graphdb.auth.oauth.roles_claim: "roles"
    graphdb.auth.oauth.roles_prefix: "GDB_"
    graphdb.auth.oauth.default_roles: "ROLE_USER"
```

Assuming GraphDB has been set up as above and you have the secret configured, you can now configure the automated
scripts to connect to GraphDB.

```yaml
security:
  enabled: true
  admin:
    initialPassword: "{bcrypt}$2a$12$VDd8PrAndaJfoMJFlHFot.osSxZWQjMQZKgrEJgVZKFj6WFPvkbnS" # admin123
  provisioner:
    username: graphdb-provisioner
    password: provisionerpass123
  oauth2:
    enabled: true
    existingSecret: "gdb-sso"
    clientIdKey: "clientId"
    clientSecretKey: "clientSecret"
    tokenUrlKey: "tokenUrl"
    scopesKey: "scopesKey"
```

## Testing

The easiest way to test this is the repository provisioner. For this purpose, create a GraphDB repository configuration.
You can use the provided `./test.ttl`. First, set up the necessary configmap:

```bash
kubectl create configmap repos --from-file test.ttl=test.ttl
```

Then, you can add the following to `values.yaml` to run it:
```bash
repositories:
  existingConfigmap: "repos"
```

Now, if you run the Helm chart, observe the repository creation job which should run after GraphDB is initialized. A
repository called "test" should be created and there should be no SSO-created errors in the repository creation job logs.
* If there are errors such as `OAuth2: token request failed`, there has been an Entra ID configuration issue.
* If there are errors such as `OAuth2: missing *`, you have missed one of the needed configuration values.
* If there are other errors, there may be an issue with the `test.ttl` format.
