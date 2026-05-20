OpenID Connect Client Authentication
===

When GraphDB acts as an OpenID Connect client with `graphdb.auth.openid.proxy=true`,
it calls the identity provider's token endpoint to exchange authorization codes for
tokens. Some identity providers require GraphDB to authenticate itself during these
calls.

The `graphdb.auth.openid.client.auth.type` property controls the authentication
method. The default is `none`, which preserves existing behaviour.

> **Note:** All methods in this guide require `graphdb.auth.openid.proxy=true`.

## Methods

| Method | Values file | Description |
|---|---|---|
| `none` | [values-none.yaml](./values-none.yaml) | No client authentication (default) |
| `client_secret_basic` | [values-client-secret-basic.yaml](./values-client-secret-basic.yaml) | Client ID + secret as HTTP Basic auth header |
| `client_secret_post` | [values-client-secret-post.yaml](./values-client-secret-post.yaml) | Client secret sent in the request body |
| `client_secret_jwt` | [values-client-secret-jwt.yaml](./values-client-secret-jwt.yaml) | Short-lived JWT signed with the client secret |
| `private_key_jwt` | [values-private-key-jwt.yaml](./values-private-key-jwt.yaml) | Short-lived JWT signed with a private key from a PKCS12 keystore |

---

## none (default)

No additional configuration needed. Preserves existing behaviour.

[values-none.yaml](./values-none.yaml)

```yaml
configuration:
  properties:
    graphdb.auth.openid.proxy: "true"
    graphdb.auth.openid.client.auth.type: "none"
```

---

## client_secret_basic

Client ID and secret are sent as an HTTP Basic Authentication header.

[values-client-secret-basic.yaml](./values-client-secret-basic.yaml)

```yaml
configuration:
  properties:
    graphdb.auth.openid.proxy: "true"
    graphdb.auth.openid.client.auth.type: "client_secret_basic"
  secretProperties:
    graphdb.auth.openid.client_secret: "your-client-secret"
```

---

## client_secret_post

Client secret is added to the request body. Used by providers that do not
support Basic auth.

[values-client-secret-post.yaml](./values-client-secret-post.yaml)

```yaml
configuration:
  properties:
    graphdb.auth.openid.proxy: "true"
    graphdb.auth.openid.client.auth.type: "client_secret_post"
  secretProperties:
    graphdb.auth.openid.client_secret: "your-client-secret"
```

---

## client_secret_jwt

A short-lived JWT is generated, signed with the client secret, and sent as
a `client_assertion` parameter. More secure than sending the secret directly.

The default signing algorithm is `HS256` but can be overridden via
`graphdb.auth.openid.client.auth.signature_alg`.

[values-client-secret-jwt.yaml](./values-client-secret-jwt.yaml)

```yaml
configuration:
  properties:
    graphdb.auth.openid.proxy: "true"
    graphdb.auth.openid.client.auth.type: "client_secret_jwt"
    graphdb.auth.openid.client.auth.signature_alg: "HS256"  # optional
  secretProperties:
    graphdb.auth.openid.client_secret: "your-client-secret"
```

---

## private_key_jwt

A short-lived JWT is signed with a private key from a PKCS12 keystore. The
secret never leaves the server, making this the most secure method.

The default signing algorithm is `RS256` but can be overridden via
`graphdb.auth.openid.client.auth.signature_alg`.

The keystore must be in PKCS12 format and the private key must be the first
entry. If `graphdb.auth.openid.client.auth.private_key_password` is not set,
it defaults to `graphdb.auth.openid.client.auth.keystore_password`.

[values-private-key-jwt.yaml](./values-private-key-jwt.yaml)

### Creating the keystore Secret

```bash
kubectl create secret generic graphdb-oidc-keystore \
  --from-file=keystore.p12=/path/to/your/keystore.p12
```

### Helm values

```yaml
extraVolumes:
  - name: oidc-keystore
    secret:
      secretName: graphdb-oidc-keystore

extraVolumeMounts:
  - name: oidc-keystore
    mountPath: /opt/graphdb/home/oidc-keystore
    readOnly: true

configuration:
  properties:
    graphdb.auth.openid.proxy: "true"
    graphdb.auth.openid.client.auth.type: "private_key_jwt"
    graphdb.auth.openid.client.auth.keystore: "/opt/graphdb/home/oidc-keystore/keystore.p12"
    graphdb.auth.openid.client.auth.signature_alg: "RS256"  # optional
  secretProperties:
    graphdb.auth.openid.client.auth.keystore_password: "changeit"
    graphdb.auth.openid.client.auth.private_key_password: "changeit"  # optional, defaults to keystore_password
```
