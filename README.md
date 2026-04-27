# Serve Invenio Deployment

This repository contains the Helm chart and Serve-specific configuration used to
deploy Invenio with Argo CD.

The deployment is based on upstream `helm-invenio`, with a small set of Serve
overrides layered on top in [values-overrides.yaml](/Users/hamim160/Documents/GitHub/ScilifelabDataCentre/serve-invenio/values-overrides.yaml).

## Default Deployment

- chart defaults shared across environments live in
  [values-overrides.yaml](values-overrides.yaml)
- environment-specific values (hostname, image registry/repository/tag,
  DataCite DOI prefix, storage class and size, cert-manager cluster issuer,
  TLS secret name, namespace) are set on the Argo CD Application
- OpenSearch: internal chart dependency
- RabbitMQ: internal chart dependency
- PostgreSQL: internal chart dependency
- Redis: internal chart dependency
- DataCite: disabled by default

## What This Repo Owns

- the Helm chart Argo deploys
- the Serve image override
- the deployment defaults in `values-overrides.yaml`
- Invenio configuration that differs from upstream defaults
- operational helper scripts that are specific to this deployment

## What This Repo Does Not Own

- Bitwarden sync
- NetworkPolicies for cross-namespace access to Invenio (owned by `serve-charts`)

These should be handled outside this repository.

## Deployment

Argo CD should deploy this chart with [values-overrides.yaml](/Users/hamim160/Documents/GitHub/ScilifelabDataCentre/serve-invenio/values-overrides.yaml).

For first-time deployment, temporarily enable:

```yaml
invenio:
  init: true
```

After the initial install job has completed successfully, set `invenio.init`
back to `false`.
If you want to render or test the chart locally:

```bash
helm upgrade --install invenio ./ -n invenio -f values-overrides.yaml
```

## Current Serve Overrides

Compared with upstream `helm-invenio`, this repo currently overrides:

- the container image to use the custom Serve image
- release naming via `fullnameOverride: invenio`
- trusted host settings for in-cluster service access
- existing secret references for Invenio, PostgreSQL, RabbitMQ, and optionally DataCite
- the Celery beat scheduler class needed for InvenioRDM v13 Jobs
- persistence storage class
- a few web/worker resource and probe settings

## Jobs And Scheduled Vocabulary Imports

This deployment enables the InvenioRDM v13 Jobs scheduler via:

- `workerBeat.schedulerClass: invenio_jobs.services.scheduler:RunScheduler`

That means the `worker-beat` deployment can execute Jobs created in the
administration UI, including the default ROR vocabulary jobs such as `Load ROR
funders`, as long as the deployed image actually includes the InvenioRDM v13
jobs/task registrations.

## Secrets

The chart expects Kubernetes secrets to already exist in the target namespace.
In particular, [values-overrides.yaml](/Users/hamim160/Documents/GitHub/ScilifelabDataCentre/serve-invenio/values-overrides.yaml)
references `invenio-bitwarden-secrets` for:

- Invenio application secrets
- PostgreSQL password
- RabbitMQ password
- RabbitMQ Erlang cookie
- Flower basic auth
- DataCite credentials when DataCite is enabled

It can also create a default admin user and a default machine user from that same secret if
these keys are present:

- `DEFAULT_ADMIN_EMAIL`
- `DEFAULT_ADMIN_PASSWORD`
- `DEFAULT_MACHINE_EMAIL`
- `DEFAULT_MACHINE_PASSWORD`

The default users are managed by a separate Helm hook job that runs on both
install and upgrade, and it adds the `admin` role to those users if the secret
keys are present.

## Reset And Recreate

For test or non-production environments, the repository includes
[scripts/wipe_recreate.sh](/Users/hamim160/Documents/GitHub/ScilifelabDataCentre/serve-invenio/scripts/wipe_recreate.sh)
to wipe the current Invenio state and recreate an empty instance with fixtures.

It does the following:

- flushes Redis
- drops the database tables
- destroys and reinitializes the search indices
- recreates the default file location at `/opt/invenio/var/instance/data`
- recreates the core roles
- initializes custom fields
- loads `invenio rdm-records fixtures`

It does not load demo records.

Example usage:

```bash
kubectl -n invenio get pods
kubectl cp scripts/wipe_recreate.sh invenio/<web-pod-name>:/tmp/wipe_recreate.sh -c web
kubectl exec -n invenio <web-pod-name> -c web -- chmod +x /tmp/wipe_recreate.sh
echo "y" | kubectl exec -n invenio <web-pod-name> -c web -i -- /tmp/wipe_recreate.sh
```

This script is useful for rebuilding a clean test instance. It should not be
used as a substitute for a real data restore or migration procedure.

## Create An Admin User

```bash
kubectl -n invenio exec -it <web-pod-name> -c web -- /bin/bash
invenio users create <admin-email> --password=<admin-password> --active
invenio roles add <admin-email> admin
exit
```

If `DEFAULT_ADMIN_EMAIL` and `DEFAULT_ADMIN_PASSWORD` are present in the
existing secret, this manual step is no longer needed for first install.

## Data Restore And Updates

For real data migration or refreshes, restore the PostgreSQL data, files, and
other state. Do not use
`wipe_recreate.sh` for that, because it intentionally resets the instance and
loads only base fixtures.

## DataCite

DataCite is intentionally disabled by default:

- `invenio.datacite.enabled: false`

That keeps the default deployment behavior aligned with the Serve expectation
that records can flow into Invenio without minting DataCite DOIs unless
explicitly enabled.
