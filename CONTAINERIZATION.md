# Contoso Air - Containerization and AKS Deployment

This document describes the containerization setup for the Contoso Air application and its deployment to Azure Kubernetes Service (AKS).

## Container Configuration

### Dockerfile
- **Base Image**: `node:22-alpine` (matches application requirement)
- **Security**: Non-root user (nodejs:1001)
- **Port**: 3000 (configurable via PORT environment variable)
- **Health Check**: HTTP check on port 3000
- **Build Context**: Root directory (includes src/web)

### Build Commands
```bash
# Build the Docker image
docker build -t contoso-air:latest .

# Run locally for testing
docker run -p 3000:3000 contoso-air:latest
```

## Kubernetes Manifests

The `k8s/` directory contains production-ready Kubernetes manifests with security best practices:

### ConfigMap (`k8s/configmap.yaml`)
- Environment variables for the application
- PORT and NODE_ENV configuration

### Deployment (`k8s/deployment.yaml`)
- **Replicas**: 3 for high availability
- **Security**: 
  - Non-root execution
  - RuntimeDefault seccomp profile
  - All capabilities dropped
  - Read-only root filesystem disabled (required for Node.js)
- **Health Checks**:
  - Startup probe: 10s delay, 30 attempts
  - Liveness probe: 30s interval
  - Readiness probe: 10s interval
- **Resources**: 100m CPU / 128Mi memory requests, 500m CPU / 512Mi memory limits
- **Anti-Affinity**: Spreads pods across nodes for resilience
- **Topology Spread**: Distributes pods across zones

### Service (`k8s/service.yaml`)
- **Type**: LoadBalancer for external access
- **Port**: 80 (external) → 3000 (internal)

## GitHub Actions Workflow

The `.github/workflows/deploy-to-aks.yml` provides continuous deployment:

### Features
- **Container Registry**: GitHub Container Registry (ghcr.io)
- **Image Tagging**: SHA-based and branch-based tags
- **Security**: Uses GitHub token for registry access
- **Azure Integration**: Azure CLI and AKS authentication
- **Deployment**: Uses Azure Kubernetes Deploy action

### Required Secrets
Configure these secrets in your GitHub repository:

```
AZURE_CREDENTIALS - Azure service principal credentials (JSON format)
AZURE_RESOURCE_GROUP - Name of the Azure resource group
AZURE_CLUSTER_NAME - Name of the AKS cluster
```

### Azure Service Principal Setup
```bash
# Create service principal
az ad sp create-for-rbac --name "contoso-air-github" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group} \
  --sdk-auth
```

## Deployment Instructions

### Prerequisites
1. Azure subscription with AKS cluster
2. GitHub repository with secrets configured
3. Azure Container Registry or GitHub Container Registry access

### Manual Deployment
```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/

# Check deployment status
kubectl get pods -l app=contoso-air
kubectl get service contoso-air-service

# Get external IP
kubectl get service contoso-air-service --watch
```

### Continuous Deployment
1. Push code to main branch
2. GitHub Actions will automatically:
   - Build Docker image
   - Push to container registry
   - Deploy to AKS cluster

## Security Features

### Container Security
- **Base Image**: Official Node.js Alpine image (minimal attack surface)
- **Non-root User**: Application runs as user ID 1001
- **Health Checks**: Built-in container health monitoring

### Kubernetes Security
- **Pod Security Standards**: Baseline compliance
- **Security Context**: RuntimeDefault seccomp profile
- **Capabilities**: All Linux capabilities dropped
- **Network Policies**: Can be added for network segmentation

### Access Control
- **RBAC**: Use Kubernetes RBAC for fine-grained permissions
- **Network Policies**: Implement network segmentation as needed
- **Secrets Management**: Use Azure Key Vault integration for sensitive data

## Monitoring and Observability

### Built-in Features
- **Health Endpoints**: Startup, liveness, and readiness probes
- **Metrics**: Express Prometheus bundle included in application
- **Logging**: Container logs available via kubectl logs

### Recommended Additions
- **Azure Monitor**: Container insights for AKS
- **Application Insights**: For application performance monitoring
- **Log Analytics**: For centralized logging

## Scaling and Performance

### Horizontal Pod Autoscaler
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: contoso-air-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: contoso-air
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Cluster Autoscaler
Configure AKS cluster autoscaler for automatic node scaling based on resource demands.

## Troubleshooting

### Common Issues
1. **Image Pull Errors**: Verify container registry access and image tags
2. **Pod Startup Failures**: Check resource limits and environment variables
3. **Service Access**: Ensure LoadBalancer has external IP assigned
4. **Health Check Failures**: Verify application is listening on port 3000

### Debug Commands
```bash
# Check pod logs
kubectl logs -l app=contoso-air

# Describe pod for events
kubectl describe pod -l app=contoso-air

# Check service endpoints
kubectl get endpoints contoso-air-service

# Port forward for local testing
kubectl port-forward service/contoso-air-service 8080:80
```