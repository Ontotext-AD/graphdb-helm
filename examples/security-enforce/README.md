Enforcing GraphDB Security
===

This example shows how to lock GraphDB security so it cannot be disabled
through the Workbench or REST API.

## Background

GraphDB has two related properties:

| Property | Purpose |
|---|---|
| `security.enabled` | Original toggle; controls security on/off |
| `graphdb.auth.security.enabled` | New immutable lock; if set, prevents further changes |

When `graphdb.auth.security.enabled` is set it takes precedence over
`security.enabled`. Any attempt to alter the security state through the
Workbench or the REST API will be rejected.

The solution is backwards compatible: deployments that do not use
`graphdb.auth.security.enabled` are unaffected.

## Single-node setup

Set the property via `configuration.properties` and enable security through
the chart's `security` block:

```yaml
configuration:
  properties:
    graphdb.auth.security.enabled: "true"

security:
  enabled: true
  admin:
    initialPassword: "{bcrypt}$2a$12$VDd8PrAndaJfoMJFlHFot.osSxZWQjMQZKgrEJgVZKFj6WFPvkbnS" # admin123
  provisioner:
    username: provisioner
    passwordHash: "$2b$12$kCFzg6FJGFRulAxbkR6VPO1URlDiiY3hE4X6NGv/4FCipHg2hxzfG" # iHaveSuperpowers
```

## Cluster setup

All cluster nodes **must** carry identical values for both
`graphdb.auth.security.enabled` and `security.enabled`. Mismatching nodes
will produce one of the following errors and block cluster creation or node
addition:

- `Mismatching security settings. Enable security on node` — one or more
  nodes have a different security state.
- `Mismatching security settings. Security on node can not be altered` — at
  least one node has `graphdb.auth.security.enabled` set and at least one
  other does not.

## Deploy

```bash
helm upgrade --install graphdb ontotext/graphdb \
  --values values.yaml
```