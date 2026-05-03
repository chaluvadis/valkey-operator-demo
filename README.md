# Valkey Operator Helm Chart

A production-ready Helm chart for deploying the Valkey Operator on Kubernetes. This chart deploys the Valkey Operator as a Kubernetes Deployment with configurable RBAC, namespace isolation, and resource management.

## Overview

The Valkey Operator manages Valkey clusters (a Redis-compatible in-memory data store) running on Kubernetes. It watches for `ValkeyCluster` custom resources and automatically provisions, scales, and manages Valkey clusters based on the desired state specified in those resources.

## What Happens After Installation

After installing this Helm chart, the following components are deployed:

1. **ServiceAccount** (`<release-name>-valkey-operator`) - Dedicated service account for the operator with least-privilege access.

2. **Role & RoleBinding** - Grants the operator permissions to manage Kubernetes resources within the target namespace:
   - Pods, Services, ConfigMaps, Secrets
   - Deployments and StatefulSets
   - ValkeyCluster custom resources (CRDs)
   - Events for logging operator activity

3. **ClusterRole & ClusterRoleBinding** - Grants cluster-scoped permissions for:
   - Watching namespaces
   - Watching CustomResourceDefinitions (for ValkeyCluster CRD discovery)
   - Watching ValkeyCluster resources across all namespaces

4. **Deployment** - Runs the Valkey Operator container with:
   - Configurable replica count (default: 1)
   - Resource limits and requests
   - Node selector, tolerations, and affinity rules
   - Custom container image support

Once the operator pod is running, you can create `ValkeyCluster` custom resources to deploy and manage Valkey clusters. The operator will automatically create the necessary StatefulSets, Services, and ConfigMaps to run your Valkey clusters.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Valkey Operator container image (default: `myrepo/valkey-operator:latest`)

## Installation

### Basic Installation

```bash
helm repo add valkey-operator ./valkey-operator-chart
helm install valkey-operator valkey-operator/valkey-operator
```

### Custom Image Installation

To use the custom container image `ghcr.io/chaluvadis/valkey-operator:16d938e`:

```bash
helm install valkey-operator ./valkey-operator-chart \
  --set image.repository=ghcr.io/chaluvadis/valkey-operator \
  --set image.tag=16d938e \
  --set image.pullPolicy=IfNotPresent
```

### Installation in a Specific Namespace

```bash
helm install valkey-operator ./valkey-operator-chart \
  --namespace my-namespace \
  --create-namespace
```

## Configuration

The following table lists the configurable parameters of the Valkey Operator chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of operator replicas | `1` |
| `image.repository` | Operator container image repository | `myrepo/valkey-operator` |
| `image.tag` | Operator container image tag | `latest` |
| `image.pullPolicy` | Container image pull policy | `IfNotPresent` |
| `namespace` | Namespace to deploy the operator into | `valkey-operator` |
| `resources.limits.cpu` | CPU resource limit | `500m` |
| `resources.limits.memory` | Memory resource limit | `256Mi` |
| `resources.requests.cpu` | CPU resource request | `100m` |
| `resources.requests.memory` | Memory resource request | `128Mi` |
| `nodeSelector` | Node labels for pod assignment | `{}` |
| `tolerations` | Tolerations for pod assignment | `[]` |
| `affinity` | Affinity rules for pod assignment | `{}` |
| `serviceAccount.create` | Create a new service account | `true` |
| `serviceAccount.name` | Name of the service account (defaults to fullname) | `""` |
| `rbac.create` | Create RBAC resources | `true` |

Specify each parameter using the `--set key=value` argument to `helm install`. For example:

```bash
helm install valkey-operator ./valkey-operator-chart \
  --set replicaCount=2 \
  --set resources.limits.memory=512Mi \
  --set nodeSelector.\"beta\.kubernetes\.io/arch\"=amd64
```

Alternatively, you can provide a custom `values.yaml` file:

```bash
helm install valkey-operator ./valkey-operator-chart -f my-values.yaml
```

## Post-Installation Steps

After the operator is running, create a `ValkeyCluster` custom resource to deploy a Valkey cluster:

```yaml
apiVersion: valkey.io/v1
kind: ValkeyCluster
metadata:
  name: my-valkey-cluster
  namespace: valkey-operator
spec:
  size: 3
  version: "7.0"
```

Apply it with:

```bash
kubectl apply -f valkey-cluster.yaml
```

The operator will detect this resource and automatically create the necessary StatefulSet, headless Service, and ConfigMap for your Valkey cluster.

## Verification

Check that the operator pod is running:

```bash
kubectl get pods -n valkey-operator
```

View operator logs:

```bash
kubectl logs -f deployment/valkey-operator -n valkey-operator
```

List ValkeyCluster resources:

```bash
kubectl get valkeyclusters -n valkey-operator
```

## Uninstallation

To uninstall the Valkey Operator:

```bash
helm uninstall valkey-operator
```

This removes all Kubernetes components associated with the chart, including the Deployment, ServiceAccount, RBAC resources, and any associated ConfigMaps/Services created by the operator. However, it **does not** delete the ValkeyCluster custom resources or the Valkey clusters managed by the operator. You may need to delete those manually before uninstalling.

## Upgrading

To upgrade to a new version of the operator, update the image tag in your values file or via `--set`:

```bash
helm upgrade valkey-operator ./valkey-operator-chart \
  --set image.tag=16d938e
```

The operator Deployment will be updated with a rolling update strategy.

## Architecture

The Valkey Operator follows the Kubernetes Operator pattern:

1. **Controller**: Watches for ValkeyCluster custom resources and reconciles the actual state with the desired state.
2. **Reconciliation Loop**: For each ValkeyCluster, ensures the correct number of replicas, configuration, and networking are in place.
3. **Event Handling**: Reacts to changes in ValkeyCluster resources, Valkey pod failures, and configuration updates.

## Troubleshooting

### Operator pod not starting

Check for resource constraints:
```bash
kubectl describe pod/<operator-pod> -n valkey-operator
```

### ValkeyCluster not being processed

Check operator logs for errors:
```bash
kubectl logs -f deployment/valkey-operator -n valkey-operator
```

### Image pull errors

Ensure the image repository and tag are correct, and that the cluster has access to pull the image. For private registries, create a Kubernetes image pull secret and reference it in the `imagePullSecrets` field.

## License

This Helm chart is provided as-is for deploying the Valkey Operator. Check the Valkey Operator container image for its specific license terms.

## Support

For issues related to the Valkey Operator itself, please refer to the [Valkey Operator documentation](https://github.com/valkey-io/valkey-operator).

For issues with this Helm chart, please open an issue in the repository.