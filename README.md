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
# Add the chart repository:
helm repo add serve-invenio https://your-organization.github.io/serve-invenio/
helm repo update

# Create a separate namespace
kubectl create namespace invenio

# Deploy external services
kubectl apply -f examples/opensearch.yaml -n invenio
kubectl apply -f examples/rabbit-mq.yaml -n invenio


# Installation with custom values
helm install invenio serve-invenio/serve-invenio -n invenio \
  --values values-overrides.yaml

# Populate Database
kubectl cp scripts/wipe_recreate.sh invenio/invenio-web-xxxx:/tmp/wipe_recreate.sh -c web
kubectl exec -n invenio invenio-web-invenio-web-xxxx -c web -- chmod +x /tmp/wipe_recreate.sh
echo "y" | kubectl exec -n invenio invenio-web-xxxx -c web -i -- /tmp/wipe_recreate.sh

# create an admin user
kubectl -n invenio exec -it invenio-web-xxxx -- /bin/bash
invenio users create admin@scilifelab.se --password=123456 --active
invenio roles add admin@scilifelab.se admin

# Delete it completely
helm uninstall invenio -n invenio --ignore-not-found
kubectl delete namespace invenio --ignore-not-found=true
