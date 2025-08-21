# AWS Cloud Backup Examples

The examples here show different ways of configuring the cloud backup CronJob to send backups in [AWS S3](https://aws.amazon.com/s3/) and
how to authenticate in AWS:

* Using inline credentials
* Using credentials from a Secret
* Using ServiceAccount and [IRSA](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)

## Inline Credentials

⚠️ **Warning:** This example is not recommended. Instead of using long term credentials, consider using a ServiceAccount.

The easiest and most straightforward way is to configure long-term credentials in the S3 bucket URI property:

```yaml
backup:
  enabled: true
  type: cloud
  cloud:
    bucketUri: s3:///<bucket>/<folder>/${BACKUP_NAME}?region=<region>&AWS_ACCESS_KEY_ID=<key>&AWS_SECRET_ACCESS_KEY=<secret>
```

Where:

- `<bucket>` is the name of your bucket.
- `<folder>` is an optional path argument, you can skip it for storing the backup at the root.
- `${BACKUP_NAME}` is replaced with an auto-generated name. Optionally, you can use a fixed name.
- `<key>` is the key of your static AWS credentials.
- `<secret>` is the secret of your static AWS credentials.

## Credentials from a Secret

⚠️ **Warning:** This example is not recommended. Instead of using long-term credentials, consider using a ServiceAccount.

In order to avoid providing static credentials in `values.yaml` for obvious security reasons, you can move them to a Kubernetes Secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: graphdb-backup-s3-credentials
type: Opaque
stringData:
  ACCESS_KEY_ID: "XXXXX"
  ACCESS_KEY: "XXXXX"
```

You can then configure your `values.yaml` like so:

```yaml
backup:
  enabled: true
  type: cloud
  cloud:
    bucketUri: s3:///<bucket>/${BACKUP_NAME}?region=<region>&AWS_ACCESS_KEY_ID=${ACCESS_KEY_ID}&AWS_SECRET_ACCESS_KEY=${ACCESS_KEY}
  extraEnvFrom:
  - secretRef:
      name: graphdb-backup-s3-credentials
```

The backup script will pick up the environment variables and interpolate them using the passed environment variables.

## Using ServiceAccount and IRSA

Instead of hardcoding credentials in `values.yaml` or arbitrary Kubernetes Secrets, the best solution is to use temporary credentials
provided by a ServiceAccount mapped to an IAM role in AWS. This ServiceAccount can be used by GraphDB to obtain temporary credentials for
interacting with the S3 bucket as long as the role mapped to the ServiceAccount has the necessary permissions for the given bucket.
See https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html.

In the next example, the chart is configured to create a new ServiceAccount for GraphDB with a special AWS EKS annotation that will map the
ServiceAccount to an IAM role:

```yaml
backup:
  enabled: true
  type: cloud
  schedule: "@midnight"
  cloud:
    bucketUri: s3:///<bucket>/${BACKUP_NAME}?region=<region>
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::<AWS_ACCOUNT_ID>:role/<ROLE_NAME>
```

Where:

- `AWS_ACCOUNT_ID` is the account in which the IAM role exists
- `ROLE_NAME` is the name of the IAM role that will be mapped to the ServiceAccount

Effectively, when a new backup request is received by GraphDB, it will use the AWS SDK to obtain temporary credentials via the
ServiceAccount.

## Customizing

### Reuse Backup Name

You can configure the backups to reuse the same name for every new backup like so:

```yaml
backup:
  enabled: true
  type: cloud
  cloud:
    bucketUri: s3:///<bucket>/<folder>/backup.tar?region=<region>
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

See https://graphdb.ontotext.com/documentation/11.1/backup-and-restore.html#backup-options for supported options.
