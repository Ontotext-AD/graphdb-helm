# Local GraphDB Backups Example

This example shows how to configure the Helm chart with local GraphDB backups backed by an existing Persistence Volume Claim.

## Configuration

The default [values.yaml](values.yaml) in the example uses a simple PVC that should be sufficient for demonstration purposes.
Ideally, you should consider using a PVC with cross-zone or cross-region data replication for better resiliency.

Keep in mind that the chart does not rotate backups, this is up to you and your retention policy.

## Usage

```bash
helm upgrade --install --values ./values.yaml graphdb ontotext/graphdb
```
