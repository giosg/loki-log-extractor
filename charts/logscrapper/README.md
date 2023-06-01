# Logscrapper

This Helm chart deploys a CronJob in Kubernetes to run a Docker image that executes a logcli query.

## Prerequisites

- Kubernetes cluster
- Helm 3+

## Configuration

The following table lists the configurable parameters of the My Chart:

| Parameter               | Description                          | Default                              |
|-------------------------|--------------------------------------|--------------------------------------|
| `logcliPath`            | Path to logcli executable             | "/path/to/logcli"                    |
| `lokiaddr`              | Log endpoint URL                      | "http://example.com/logs"            |
| `startTime`             | Start time for log query              | "2023-05-01T00:00:00Z"               |
| `endTime`               | End time for log query                | "2023-05-15T23:59:59Z"               |
| `outputFile`            | Output file name                      | "logs_output.txt"                    |
| `compressedFile`        | Compressed file name                  | "logs_output.txt.gz"                 |
| `encryptedFile`         | Encrypted file name                   | "logs_output.txt.gz.gpg"             |
| `s3Bucket`              | S3 bucket name for log storage        | "your-s3-bucket"                     |
| `awsSecretName`         | Name of the AWS credentials secret    | "aws-credentials"                    |
| `gpgSecretName`         | Name of the GPG public key secret      | "gpg-public-key"                     |
| `logcliQuery`           | Logcli query to execute                | "logcli_query"                       |
| `cronSchedule`          | Cron schedule for the CronJob         | "0 0 * * *"                          |
| `image.repository`      | Docker image repository               | (required)                            |
| `image.tag`             | Docker image tag                      | (required)                            |
| `image.pullPolicy`      | Docker image pull policy              | "IfNotPresent"                        |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. Alternatively, you can create a YAML file containing the values and provide it to the `helm install` command with the `-f` or `--values` flag.

## Secrets

This chart expects the AWS credentials and GPG public key to be stored as Kubernetes Secrets. Ensure that you create the secrets before deploying the chart.

### AWS Credentials Secret

The AWS credentials secret should contain the following keys:

- `awsAccessKeyId`: AWS access key ID
- `awsSecretAccessKey`: AWS secret access key

### GPG Public Key Secret

The GPG public key secret should contain the following key:

- `gpgPublicKey`: Base64-encoded GPG public key

## Installing the Chart

```ShellSession
$ helm install --dry-run --debug -n loki logscrapper logscrapper
```

For full installation please remove from the command above two options:
 --dry-run --debug