# Containerization and AKS Deployment

This document describes how to containerize the Contoso Air application and deploy it to Azure Kubernetes Service (AKS).

## Overview

The application has been containerized using Docker and configured for deployment to Azure Kubernetes Service (AKS) with the following components:

- **Dockerfile**: Multi-stage build with Node.js 22 Alpine Linux
- **Kubernetes Manifests**: Deployment, Service, and ConfigMap
- **CI/CD Pipeline**: GitHub Actions workflow for automated build and deployment

## Local Development

### Build and Run with Docker

```bash
# Build the Docker image
docker build -t contoso-air .

# Run the container locally
docker run -p 3000:3000 contoso-air

# Test the application
curl http://localhost:3000
```

### Environment Variables

The application supports the following environment variables:

- `PORT`: Application port (default: 3000)
- `NODE_ENV`: Node.js environment (default: production)
- `AZURE_COSMOS_LISTCONNECTIONSTRINGURL`: Azure CosmosDB connection string URL
- `AZURE_COSMOS_SCOPE`: Azure CosmosDB scope
- `AZURE_COSMOS_CLIENTID`: Azure Managed Identity client ID

## Kubernetes Deployment

### Prerequisites

- Azure Kubernetes Service (AKS) cluster
- Azure Container Registry (ACR)
- kubectl configured for your AKS cluster

### Manual Deployment

```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/

# Check deployment status
kubectl get pods -l app=contoso-air
kubectl get services -l app=contoso-air

# Get external IP
kubectl get service contoso-air-service
```

### Configuration

Update the following files for your environment:

1. **`.github/workflows/deploy-to-aks.yml`**:
   - `AZURE_CONTAINER_REGISTRY`: Your ACR name
   - `RESOURCE_GROUP`: Your resource group name
   - `CLUSTER_NAME`: Your AKS cluster name

2. **`k8s/deployment.yaml`**:
   - Update the `image` field with your ACR URL

## CI/CD Pipeline

### GitHub Secrets Required

Configure the following secrets in your GitHub repository:

- `AZURE_CLIENT_ID`: Azure service principal client ID
- `AZURE_TENANT_ID`: Azure tenant ID
- `AZURE_SUBSCRIPTION_ID`: Azure subscription ID

### Workflow Triggers

The CI/CD pipeline triggers on:

- Push to `main` branch
- Pull requests to `main` branch
- Manual workflow dispatch

### Pipeline Steps

1. **Build**: Builds Docker image and pushes to ACR
2. **Deploy**: Deploys to AKS using Kubernetes manifests

## Security Features

The deployment includes several security best practices:

### Docker Security
- Non-root user (nodejs:1001)
- Minimal Alpine Linux base image
- Health checks
- Resource constraints

### Kubernetes Security
- Pod Security Standards compliance
- SecurityContext with RuntimeDefault seccomp profile
- Non-root container execution
- Dropped Linux capabilities
- Pod anti-affinity for resilience
- Resource limits and requests

### High Availability
- 3 replicas by default
- Pod anti-affinity rules
- Topology spread constraints
- Comprehensive health probes (liveness, readiness, startup)

## Monitoring and Troubleshooting

### View Logs
```bash
# View application logs
kubectl logs -l app=contoso-air -f

# View specific pod logs
kubectl logs <pod-name> -f
```

### Debug Deployment
```bash
# Check pod status
kubectl describe pods -l app=contoso-air

# Check service endpoints
kubectl get endpoints contoso-air-service

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## Scaling

```bash
# Scale deployment
kubectl scale deployment contoso-air-deployment --replicas=5

# View horizontal pod autoscaler (if configured)
kubectl get hpa
```

## Clean Up

```bash
# Delete all resources
kubectl delete -f k8s/

# Or delete by label
kubectl delete all -l app=contoso-air
```