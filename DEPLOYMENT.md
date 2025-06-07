# Contoso Air - Containerization and AKS Deployment

This project demonstrates the containerization of the Contoso Air airline booking application and its deployment to Azure Kubernetes Service (AKS) using CI/CD practices.

## Prerequisites

Before deploying the application, ensure you have the following Azure resources created:

### 1. Azure Container Registry (ACR)
```bash
# Create a resource group
az group create --name rg-contoso-air --location eastus

# Create Azure Container Registry
az acr create --resource-group rg-contoso-air --name <your-acr-name> --sku Basic
```

### 2. Azure Kubernetes Service (AKS)
```bash
# Create AKS cluster
az aks create \
  --resource-group rg-contoso-air \
  --name <your-aks-cluster> \
  --node-count 2 \
  --enable-addons monitoring \
  --attach-acr <your-acr-name>
```

### 3. GitHub Secrets
Configure the following secrets in your GitHub repository:

- `AZURE_CREDENTIALS`: Azure service principal credentials for GitHub Actions
  ```json
  {
    "clientId": "<client-id>",
    "clientSecret": "<client-secret>",
    "subscriptionId": "<subscription-id>",
    "tenantId": "<tenant-id>"
  }
  ```

## Application Architecture

### Docker Configuration
- **Base Image**: Node.js 22 Alpine
- **Application Port**: 3000
- **Security**: Non-root user execution
- **Health Checks**: Built-in HTTP health checks

### Kubernetes Configuration
The application is deployed with the following components:

#### ConfigMap
- Stores environment variables (NODE_ENV, PORT)

#### Deployment
- **Replicas**: 3 instances for high availability
- **Security Context**: RuntimeDefault seccomp profile, non-root execution
- **Resource Limits**: 512Mi memory, 500m CPU
- **Probes**: Liveness, readiness, and startup probes
- **Anti-Affinity**: Pods spread across different nodes

#### Service
- **Type**: LoadBalancer
- **Port**: 80 (external) → 3000 (internal)

## CI/CD Pipeline

The GitHub Actions workflow (`build-deploy.yml`) performs the following steps:

1. **Build Stage**:
   - Checkout source code
   - Set up Docker Buildx
   - Log in to Azure and ACR
   - Build and push Docker image with caching

2. **Deploy Stage**:
   - Set AKS context
   - Create namespace if needed
   - Update deployment manifest with new image
   - Deploy to AKS
   - Verify deployment status

## Local Development

### Build Docker Image
```bash
docker build -t contoso-air:latest .
```

### Run Container Locally
```bash
docker run -p 3000:3000 contoso-air:latest
```

### Test Application
```bash
curl http://localhost:3000
```

## Deployment

### Manual Deployment
```bash
# Update environment variables in .github/workflows/build-deploy.yml
# Push changes to trigger the CI/CD pipeline
git push origin main
```

### kubectl Deployment
```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/deployment.yaml

# Check deployment status
kubectl get pods
kubectl get services
```

## Security Features

### Container Security
- Non-root user execution (UID 1001)
- Dropped all Linux capabilities
- Read-only root filesystem where possible
- Security context constraints

### Kubernetes Security
- Pod Security Standards compliance
- RuntimeDefault seccomp profile
- Resource limits and requests
- Network policies (can be added)

## Monitoring and Observability

### Health Checks
- **Startup Probe**: Ensures container starts properly
- **Liveness Probe**: Restarts unhealthy containers
- **Readiness Probe**: Controls traffic routing

### Metrics
- Prometheus metrics available via express-prom-bundle
- Azure Monitor integration via AKS add-ons

## Scaling

### Horizontal Pod Autoscaler (HPA)
```bash
kubectl autoscale deployment contoso-air --cpu-percent=70 --min=3 --max=10
```

### Cluster Autoscaler
Configure cluster autoscaler for node-level scaling based on resource demands.

## Troubleshooting

### Common Issues

1. **Image Pull Errors**
   - Ensure ACR is attached to AKS cluster
   - Verify image exists in registry

2. **Pod Startup Issues**
   - Check application logs: `kubectl logs -f deployment/contoso-air`
   - Verify environment variables and configuration

3. **Service Connection Issues**
   - Check service endpoints: `kubectl get endpoints`
   - Verify pod labels match service selector

### Useful Commands
```bash
# View pod logs
kubectl logs -l app=contoso-air

# Debug pod issues
kubectl describe pod <pod-name>

# Check service status
kubectl get svc contoso-air-service

# Port forward for local testing
kubectl port-forward service/contoso-air-service 8080:80
```

## Configuration

### Environment Variables
Update the ConfigMap in `k8s/deployment.yaml`:
```yaml
data:
  NODE_ENV: "production"
  PORT: "3000"
  # Add additional environment variables as needed
```

### Resource Requirements
Adjust resource requests and limits based on your workload:
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test locally
4. Submit a pull request

The CI/CD pipeline will automatically build and deploy changes when merged to the main branch.