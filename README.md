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

# Create a separate namespace
kubectl create namespace invenio

# Create the secret first
# This script will randomly generate the secrets
# Do not disclose it or share
chmod +x generate-invenio-secrets.sh
./generate-invenio-secrets.sh > invenio-secrets.yaml

# Apply the secrets
kubectl apply -f invenio-secrets.yaml -n invenio

# Deploy external services
kubectl apply -f examples/opensearch.yaml -n invenio
kubectl apply -f examples/rabbit-mq.yaml -n invenio

# Installation with custom values
helm upgrade --install invenio ./ -n invenio \
  --values values-overrides.yaml

# Populate Database (make sure to locate the correct invenio-web pod, 
# for example using,
# k -n invenio get po)
kubectl cp scripts/wipe_recreate.sh invenio/invenio-serve-invenio-web-xxxxxxxxxx-xxxxx:/tmp/wipe_recreate.sh -c web
kubectl exec -n invenio invenio-serve-invenio-web-xxxxxxxxxx-xxxxx -c web -- chmod +x /tmp/wipe_recreate.sh
echo "y" | kubectl exec -n invenio invenio-serve-invenio-web-xxxxxxxxxx-xxxxx -c web -i -- /tmp/wipe_recreate.sh

# create an admin user
kubectl -n invenio exec -it invenio-web-xxxx -- /bin/bash
# run the following commands inside the pod
invenio users create admin@scilifelab.se --password=123456 --active
invenio roles add admin@scilifelab.se admin

# Delete it completely
k -n invenio delete pvc --all
kubectl delete secret invenio-secrets -n invenio
helm uninstall invenio -n invenio --ignore-not-found

# If you want to wipe out everything at once
kubectl delete namespace invenio --ignore-not-found=true
