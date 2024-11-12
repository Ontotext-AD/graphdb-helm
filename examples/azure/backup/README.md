# Azure Cloud Backup Examples

The examples here show different ways of configuring the cloud backup CronJob to send backups
in [Azure Blob Storage](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction) and how to authenticate in Azure:

* Using inline credentials
* Using credentials from a Secret
* Using ServiceAccount and [Managed Identity](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview)

## Inline Credentials

⚠️ **Warning:** This example is not recommended. Instead of using long-term credentials, consider using a ServiceAccount.

The easiest and most straightforward way is to configure long-term credentials in the blob storage URI property:

```yaml
backup:
  enabled: true
  type: cloud
  cloud:
    bucketUri: az://<storage_container>/${BACKUP_NAME}?blob_storage_account=<storage_account>&blob_access_key=<access_key>
```

Where:

- `<storage_container>` is the name of your container in the storage account.
- `${BACKUP_NAME}` is replaced with an auto-generated name. Optionally, you can use a fixed name.
- `<storage_account>` is the name of your storage account
- `<access_key>` is the long-term shared key for your storage account

## Credentials from a Secret

⚠️ **Warning:** This example is not recommended. Instead of using long-term credentials, consider using a ServiceAccount.

In order to avoid providing static credentials in `values.yaml` for obvious security reasons, you can move them to a Kubernetes Secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: graphdb-backup-azure-credentials
type: Opaque
stringData:
  ACCESS_KEY: "XXXXX"
```

You can then configure your `values.yaml` like so:

```yaml
backup:
  enabled: true
  type: cloud
  cloud:
    bucketUri: az://<storage_container>/${BACKUP_NAME}?blob_storage_account=<storage_account>&blob_access_key=${ACCESS_KEY}
  extraEnvFrom:
  - secretRef:
      name: graphdb-backup-azure-credentials
```

The backup script will pick up the environment variables and interpolate them using the passed environment variables.

## Using ServiceAccount and Managed Identity

Instead of hardcoding credentials in `values.yaml` or arbitrary Kubernetes Secrets, the best solution is to use temporary credentials
provided by a ServiceAccount mapped to a Managed Identity in Azure. This ServiceAccount can be used by GraphDB to obtain temporary
credentials for interacting with the storage container as long as the managed identity mapped to the ServiceAccount has the necessary
permissions for the given storage container. See https://learn.microsoft.com/en-us/azure/aks/workload-identity-deploy-cluster.

In the next example, the chart is configured to create a new ServiceAccount for GraphDB with a special Azure AKS annotation that will map
the ServiceAccount to a Managed Identity:

```yaml
backup:
  enabled: true
  type: cloud
  schedule: "@midnight"
  cloud:
    bucketUri: az://<storage_container>/${BACKUP_NAME}?blob_storage_account=<storage_account>
serviceAccount:
  create: true
  annotations:
    azure.workload.identity/client-id: <MANAGED_IDENTITY_CLIENT_ID>
```

Where:

- `MANAGED_IDENTITY_CLIENT_ID` is the identifier of the client for your managed identity

Effectively, when a new backup request is received by GraphDB, it will use the Azure SDK to obtain temporary credentials via the
ServiceAccount.

## Customizing

### Reuse Backup Name

You can configure the backups to reuse the same name for every new backup like so:

```yaml
backup:
  enabled: true
  type: cloud
  cloud:
    bucketUri: az://<storage_container>/backup.tar?blob_storage_account=<storage_account>
```

### Backup Options

You can also configure backup specific options by providing them directly to `backup.options`:

```yaml
backup:
  # Rendered as JSON in the backups Job
  options:
    backupSystemData: false
    repositories: [ .... ]
```

Or by passing an existing Secret object with:

```yaml
backup:
  optionsSecret:
    existingSecret: graphdb-custom-backup-options
```

See https://graphdb.ontotext.com/documentation10.backup-and-restore.html#backup-options for supported options.
