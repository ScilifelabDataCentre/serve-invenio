# Serve-Invenio Helm Chart

A production-ready Helm chart for deploying InvenioRDM with external dependencies.

## Features

- Production-ready configuration with security hardening
- External service integration (OpenSearch, RabbitMQ, PostgreSQL)
- Versioned and reproducible deployments
- Security contexts with non-root users
- Monitoring with probes and health checks
- Ingress with TLS support via cert-manager

## Quick Start

### Prerequisites

1. Kubernetes cluster (1.20+)
2. Helm 3.8+
3. Persistent storage (ReadWriteMany support)
4. Cert-manager (for TLS certificates)
5. NGINX Ingress Controller

### Installation

```bash
# Update the helm repository:
git clone https://github.com/ScilifelabDataCentre/serve-invenio.git
cd serve-invenio
helm repo update

# Create a separate namespace.
kubectl create namespace invenio

# Create the secrets first.
# This script will randomly generate the secrets.
# Note: This script does not include the correct DATACITE_USERNAME and DATACITE_PASSWORD,
# make sure to use the correct values of them if you want to mint DOI using datacite credentials
# Do not disclose it or share.
chmod +x generate-invenio-secrets.sh
./generate-invenio-secrets.sh > invenio-secrets.yaml

# Apply the secrets
kubectl apply -f invenio-secrets.yaml -n invenio

# Deploy external services
kubectl apply -f externals/opensearch.yaml -n invenio
kubectl apply -f externals/rabbit-mq.yaml -n invenio

# Installation with custom values
# Note: Make sure to set invenio.datacite.enabled to 'true' if you want to mint DOI using datacite credentials
helm upgrade --install invenio ./ -n invenio \
  --values values-overrides.yaml

# Populate Database
# make sure to locate the correct invenio-web pod, 
# for example, using,
# k -n invenio get po
kubectl cp scripts/wipe_recreate.sh invenio/invenio-serve-invenio-web-xxxxxxxxxx-xxxxx:/tmp/wipe_recreate.sh -c web
kubectl exec -n invenio invenio-serve-invenio-web-xxxxxxxxxx-xxxxx -c web -- chmod +x /tmp/wipe_recreate.sh
echo "y" | kubectl exec -n invenio invenio-serve-invenio-web-xxxxxxxxxx-xxxxx -c web -i -- /tmp/wipe_recreate.sh

# Create an admin user
kubectl -n invenio exec -it invenio-serve-invenio-web-xxxxxxxxxx-xxxxx -- /bin/bash
# run the following commands inside the pod
invenio users create <provide-admin-email> --password=<provide-admin-password> --active
invenio roles add <provide-admin-email> admin
# to exit from the pod
exit

# Delete it completely, also make sure to delete all external pods
k -n invenio delete pvc --all
kubectl delete secret invenio-cluster-secrets -n invenio
helm uninstall invenio -n invenio --ignore-not-found

# If you want to wipe out everything at once
kubectl delete namespace invenio --ignore-not-found=true
