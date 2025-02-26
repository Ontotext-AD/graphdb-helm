# GCP Cloud Backup Examples

The examples here show different ways of configuring the cloud backup CronJob to send backups
in [GCP Cloud Storage](https://cloud.google.com/storage/docs)  
and how to authenticate in GCP:

* Using [ADC with Service Account's JSON key file](https://cloud.google.com/docs/authentication/set-up-adc-local-dev-environment#local-key).
* Using [IAM Service Account impersonation](https://cloud.google.com/iam/docs/workload-identity-federation-with-kubernetes#use-service-account-impersonation) to grant access.

## ADC with Service account keys

⚠️ **Warning:** This example is not recommended. Instead of using long-term service account keys, consider using
Workload Identity Federation(Linking the GCP Service Account to Kubernetes Service Account).

The easiest and most straightforward way is to configure long-term credentials for the GCP Cloud Storage via an
environment variable:

Create the secret that contains the JSON key:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: gcp-sa-key
type: Opaque
data:
  key.json: <BASE64_ENCODED_JSON_KEY>
```

Mount the secret and create an environment variable that references it:

```yaml
backup:
  enabled: true
  type: cloud
  schedule: "@midnight"
  cloud:
    bucketUri: gs://<bucket>/<folder>/${BACKUP_NAME}

extraEnv:
  - name: GOOGLE_APPLICATION_CREDENTIALS
    value: "/secrets/key.json"

extraVolumes:
  - name: gcp-key
    secret:
      secretName: gcp-sa-key

extraVolumeMounts:
  - name: gcp-key
    mountPath: "/secrets"
```

Where:

- `<bucket>` is the name of your bucket.
- `<folder>` is an optional path argument, you can skip it for storing the backup at the root.
- `${BACKUP_NAME}` is replaced with an auto-generated name. Optionally, you can use a fixed name.
- `<mount-path>` is the path where you will mount your volume inside the GraphDB pod.
- `<json-key-reference>` is the reference to the mount path of the JSON key.

The GraphDB pod automatically detects the GOOGLE_APPLICATION_CREDENTIALS environment variable, which must specify   
the file path of the JSON credential file (rather than the file's contents directly), and uses that file to authenticate with the GCP service.

## IAM service account impersonation

Instead of hardcoding credentials in arbitrary Kubernetes Secrets, the best solution is to link a Kubernetes 
Service Account to an IAM Service Account. This way your workloads in Kubernetes can
authenticate to Google Cloud APIs and authentication happens securely via IAM Workload Identity, reducing the risk of
exposing credentials.

In the next example once
the [IAM allow policy](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#kubernetes-sa-to-iam) is
created, you can simply annotate the Kubernetes ServiceAccount:

```yaml
backup:
  enabled: true
  type: cloud
  schedule: "@midnight"
  cloud:
    bucketUri: gs://<bucket>/<folder>/${BACKUP_NAME}

serviceAccount:
  create: true
  annotations:
    iam.gke.io/gcp-service-account: <IAM_SA_NAME>@<IAM_SA_PROJECT_ID>.iam.gserviceaccount.com
```

Effectively, when a new backup request is received by GraphDB, Kubernetes workloads running under the Kubernetes
Service Account will automatically authenticate to Google Cloud APIs using the linked IAM Service Account.

## Customizing

### Reuse Backup Name

You can configure the backups to reuse the same name for every new backup like so:

```yaml
backup:
  enabled: true
  type: cloud
  cloud:
    bucketUri: gs://<bucket>/<folder>/backup.tar
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

See https://graphdb.ontotext.com/documentation/10.8/backup-and-restore.html#backup-options for supported options.
