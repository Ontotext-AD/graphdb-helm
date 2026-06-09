Audit Logs
===

This example shows how to enable GraphDB's audit trail using the Helm chart.

Audit logging enables accountability for user actions. Common use cases:

- Detect unauthorized access
- Trace configuration changes
- Prevent inappropriate actions through accountability

See the [GraphDB Security Auditing documentation](https://graphdb.ontotext.com/documentation/11.3/security-auditing.html)
for the full reference.

## Configuration

Audit logging is configured via `configuration.properties` in the Helm chart.

### Audit role

`graphdb.audit.role` controls which role level triggers logging. The hierarchy
is cumulative — each level includes all levels below it:

| Role | What gets logged |
|---|---|
| `ADMIN` | Administration resources + login form (always logged) |
| `REPO_MANAGER` | Repository management operations + everything above |
| `USER` | User-level resource access + everything above |
| `ANY` | All authenticated requests |

### Repository access

`graphdb.audit.repository` narrows which repository operations are logged:

| Value | What gets logged |
|---|---|
| `WRITE` | Write operations only |
| `READ` | Read and write operations |

### Logged fields

Every audit entry includes:

- Username
- Source IP address
- Response status code
- Request method and endpoint
- Repository (from `X-GraphDB-Repository` header or inferred)
- Selected request headers (configured via `graphdb.audit.headers`)
- Request body excerpt (up to `graphdb.audit.request.max.length` bytes, default 1024)

By default no headers are logged. To include headers, list them comma-separated:

```yaml
configuration:
  properties:
    graphdb.audit.headers: "Referer,User-Agent"
```

## Examples

### Minimum — log write operations by users

```yaml
configuration:
  properties:
    graphdb.audit.role: "USER"
    graphdb.audit.repository: "WRITE"
```

### Verbose — log all authenticated requests including reads

```yaml
configuration:
  properties:
    graphdb.audit.role: "ANY"
    graphdb.audit.repository: "READ"
    graphdb.audit.headers: "Referer,User-Agent"
    graphdb.audit.request.max.length: "2048"
```

## Deploy

```bash
helm upgrade --install graphdb ontotext/graphdb \
  --values values.yaml
```
