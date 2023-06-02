# Logscrapper

Extract logs from Loki and store them to S3 in plaintext.

Included Helm chart deploys a CronJob in Kubernetes to run a image that executes a logcli query.

## Prerequisites

- Kubernetes cluster
- Helm 3+

## Configuration

The following table lists the configurable parameters of the My Chart:

| Parameter                | Description                          | Default                              |
|--------------------------|--------------------------------------|--------------------------------------|
| `image.repository`       | Image repository                     | giosg/logscrapper                    |
| `image.tag`              | Image tag                            | latest                               |
| `image.pullPolicy`       | Image pull policy                    | IfNotPresent                         |
| `image.imagePullSecrets` | List of imagePullSecret names        | _empty list_                         |
| `logEndpoint`            | Log endpoint URL                     | http://localhost                     |
| `awsAccessKeyId`         | AWS Access Key ID                    | _empty_                              |
| `awsSecretAccessKey`     | AWS Secret Access Key                | _empty_                              |
| `awsDefaultRegion`       | AWS default region                   | eu-west-1                            |
| `s3Url`                  | S3 URL for log storage               | _empty_                              |
| `gpgPublicKey`           | gpg public key                       | _empty_                              |
| `gpgRecipient`           | gpg encrypted message recipient      | _empty_                              |

Specify a dict of queries for which cronjobs will be created under `instances`. By default instances dict is empty (no cronjobs will be installed).

| Parameter                | Description                          |
|--------------------------|--------------------------------------|
| `name.cronSchedule`      | Cron schedule for the CronJob        |
| `name.logcliQuery`       | Logcli query to execute              |
| `name.startTime`         | Start time for log query             |
| `name.endTime`           | End time for log query               |

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
