# Kubernetes Deployment

This directory contains the Kubernetes manifests for deploying the Contoso Air application to Azure Kubernetes Service (AKS).

## Files

- `deployment.yaml` - Kubernetes Deployment with security best practices
- `service.yaml` - LoadBalancer Service to expose the application
- `configmap.yaml` - Configuration for environment variables

## Deployment Features

### Security
- RuntimeDefault seccomp profile
- Non-root user execution
- Dropped Linux capabilities
- Read-only root filesystem where possible

### Resilience
- Pod anti-affinity to spread across nodes
- Topology spread constraints
- Liveness, readiness, and startup probes
- Resource limits and requests

### High Availability
- 3 replicas by default
- Load balancer service for external access

## Manual Deployment

To deploy manually to an AKS cluster:

```bash
# Apply the manifests
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Check deployment status
kubectl rollout status deployment/contoso-air

# Get service external IP
kubectl get service contoso-air-service
```

## Continuous Deployment

The application is automatically deployed via GitHub Actions when changes are pushed to the main branch. See `.github/workflows/deploy-to-aks.yml` for the full CI/CD pipeline.

## Configuration

Environment variables can be configured in the ConfigMap (`configmap.yaml`). For Azure CosmosDB integration, add the following variables:

- `AZURE_COSMOS_LISTCONNECTIONSTRINGURL`
- `AZURE_COSMOS_SCOPE`
- `AZURE_COSMOS_CLIENTID`

## Secrets

For sensitive data like connection strings, create Kubernetes secrets instead of using ConfigMaps:

```bash
kubectl create secret generic contoso-air-secrets \
  --from-literal=AZURE_COSMOS_CONNECTION_STRING="your-connection-string"
```