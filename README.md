# valkey-operator

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v0.1.0](https://img.shields.io/badge/AppVersion-v0.1.0-informational?style=flat-square)

A Helm chart for deploying the [Valkey Operator](https://github.com/valkey-io/valkey-operator) on Kubernetes. The operator manages Valkey clusters through custom resources (ValkeyCluster, ValkeyNode).

## Prerequisites

- Kubernetes 1.20+
- Helm 3.5+

## Overview

This chart deploys the Valkey Operator controller manager as a Deployment in your Kubernetes cluster. The operator watches for `ValkeyCluster` and `ValkeyNode` custom resources and manages the corresponding Valkey instances.

### Resource Naming Convention

All Kubernetes resources created by this chart use the **release name** as the base identifier:

| Resource Type | Resource Name (example: release=`valkey-cluster`) |
|---|---|
| Deployment | `valkey-cluster` |
| ServiceAccount | `valkey-cluster` |
| ClusterRole | `valkey-cluster-manager` |
| ClusterRoleBinding | `valkey-cluster-manager` |
| Role (leader election) | `valkey-cluster-leader-election` |
| RoleBinding (leader election) | `valkey-cluster-leader-election` |
| Service (metrics) | `valkey-cluster-metrics` |

**Note:** The operator image tag is derived from the chart's `appVersion` by default. Override via `image.tag` in `values.yaml`.

## Installation

Install the chart with a release name into the `valkey-operator` namespace:

```bash
helm install valkey-cluster valkey-operator \
  --namespace valkey-operator \
  --create-namespace
```

This installs the operator **and** creates a default ValkeyCluster with the following configuration:
- 3 node cluster (single shard, 3 replicas)
- Valkey version 7.2
- Persistence enabled with 1Gi storage
- Resource limits: 500m CPU, 512Mi memory per node

### Installation Options

#### Operator Only (No ValkeyCluster)

To deploy only the operator without creating a ValkeyCluster:

```bash
helm install valkey-cluster valkey-operator \
  --namespace valkey-operator \
  --create-namespace \
  --set valkeyCluster.create=false
```

#### Custom ValkeyCluster

To customize the default ValkeyCluster:

```bash
helm install valkey-cluster valkey-operator \
  --namespace valkey-operator \
  --create-namespace \
  --set valkeyCluster.name=my-production-cluster \
  --set valkeyCluster.size=6 \
  --set valkeyCluster.version="7.2" \
  --set valkeyCluster.persistence.size=10Gi
```

Or use a custom `values.yaml`:

```bash
helm install valkey-cluster valkey-operator -f my-values.yaml
```

### Custom Image Installation

To use a custom container image (e.g., from a private registry):

```bash
helm install valkey-cluster valkey-operator \
  --namespace valkey-operator \
  --create-namespace \
  --set image.registry=ghcr.io \
  --set image.repository=chaluvadis/valkey-operator \
  --set image.tag=16d938e \
  --set image.pullPolicy=IfNotPresent
```

This installs the operator with the following default configuration:
- 1 replica
- RBAC enabled (ClusterRole, ClusterRoleBinding, ServiceAccount)
- Leader election enabled for high availability
- Metrics endpoint enabled on port 8443
- Security contexts configured (non-root, read-only root filesystem, dropped capabilities)

## Upgrade Instructions

Upgrade an existing release:

```bash
helm upgrade valkey-cluster valkey-operator \
  --namespace valkey-operator \
  --values values.yaml
```

Preview changes before upgrading (requires `helm-diff` plugin):

```bash
helm diff upgrade valkey-cluster valkey-operator \
  --namespace valkey-operator \
  --values values.yaml
```

## Template Rendering (Dry Run)

Render Kubernetes manifests without applying:

```bash
helm template valkey-cluster valkey-operator \
  --namespace valkey-operator \
  --values values.yaml
```

Validate rendered manifests:

```bash
helm template valkey-cluster valkey-operator \
  --namespace valkey-operator \
  --values values.yaml | kubeconform -strict -summary
```

## Uninstallation / Removal

Remove the Helm release and all associated cluster-scoped resources:

```bash
helm uninstall valkey-cluster --namespace valkey-operator
```

### Removing Custom Resource Definitions (CRDs)

The chart's CRDs are not removed by Helm. To delete them:

```bash
kubectl delete crd valkeyclusters.valkey.io
kubectl delete crd valkeynodes.valkey.io
```

> **Warning:** Deleting CRDs permanently removes all ValkeyCluster and ValkeyNode custom resources in the cluster.

## Configuration Reference

### Essential Parameters

| Parameter | Description | Default |
|---|---|---|
| `image.repository` | Operator container image repository | `valkey-io/valkey-operator` |
| `image.tag` | Operator image tag | `""` (uses `Chart.AppVersion`) |
| `image.registry` | Container image registry | `ghcr.io` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `replicaCount` | Number of operator replicas | `1` |
| `rbac.create` | Create ClusterRole/ClusterRoleBinding | `true` |
| `manager.leaderElection.enabled` | Enable leader election for HA | `true` |
| `manager.watchNamespace` | Namespace to watch (empty = all namespaces) | `""` |
| `manager.args` | Additional CLI arguments | `[]` |
| `metrics.enabled` | Enable metrics service and endpoint | `true` |
| `metrics.port` | Metrics port | `8443` |

### Resource Requests and Limits

Configure CPU and memory for the operator container:

```yaml
resources:
  limits:
    cpu: 500m
    memory: 128Mi
  requests:
    cpu: 10m
    memory: 64Mi
```

### Security Contexts

**Pod-level security context:**
```yaml
podSecurityContext:
  runAsNonRoot: true
  seccompProfile:
    type: RuntimeDefault
```

**Container-level security context:**
```yaml
securityContext:
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
```

Adjust these settings only if required by your organization's security policy.

### Image Pull Secrets

For private container registries, configure image pull secrets:

```yaml
imagePullSecrets:
  - name: my-registry-secret
```

Or use global settings:
```yaml
global:
  imagePullSecrets:
    - name: my-registry-secret
```

### ServiceAccount Configuration

```yaml
serviceAccount:
  create: true          # Create a dedicated ServiceAccount
  name: ""             # Override name (defaults to release name)
  automount: true      # Automatically mount service account token
  annotations: {}      # Custom annotations
  labels: {}           # Custom labels
```

Set `serviceAccount.create=false` to use an existing ServiceAccount:
```yaml
serviceAccount:
  create: false
  name: existing-sa-name
```

### Namespace Watching

Control which namespaces the operator watches for ValkeyCluster resources:

```yaml
manager:
  watchNamespace: ""  # Empty = watch all namespaces (default)
  # watchNamespace: "production"  # Restrict to a single namespace
  # watchNamespace: "ns1,ns2"     # Multiple namespaces (comma-separated if supported)
```

**Default behavior:** When `watchNamespace` is empty (`""`), the operator watches all namespaces in the cluster. This is the recommended setting for a cluster-wide operator.

**Restricted watching:** Set `watchNamespace` to a specific namespace name to limit the operator's scope. This is useful for multi-tenant clusters where operators should only manage resources in designated namespaces.

**Note:** The operator must be granted RBAC permissions to access the watched namespaces. When watching all namespaces, the ClusterRole provides the necessary permissions. When watching a specific namespace, you may need to adjust RBAC accordingly.

### Node Scheduling Constraints

Control pod placement using Kubernetes scheduling features:

```yaml
nodeSelector:
  kubernetes.io/os: linux

tolerations:
  - key: "node-role.kubernetes.io/control-plane"
    operator: "Exists"
    effect: "NoSchedule"

affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/arch
              operator: In
              values:
                - amd64
                - arm64
```

### Custom Manager Arguments

Pass additional flags to the Valkey Operator binary:

```yaml
manager:
  args:
    - --health-probe-bind-address=:8081
    - --some-custom-flag=value
```

### Pod Metadata

Add custom labels and annotations to operator pods:

```yaml
podAnnotations:
  example.com/owner: "platform-team"

podLabels:
  team: infrastructure

commonLabels:
  environment: production
```

### Disabling Features

**Disable metrics endpoint:**
```yaml
metrics:
  enabled: false
```

**Disable RBAC (not recommended for production):**
```yaml
rbac:
  create: false
```

**Disable leader election (single replica only):**
```yaml
manager:
  leaderElection:
    enabled: false
```

### Resource Name Overrides

Use overrides with caution — they affect all generated resource names:

```yaml
nameOverride: "custom-name"           # Changes app.kubernetes.io/name label
fullnameOverride: "my-custom-resource" # Overrides all resource names entirely
```

## Creating a ValkeyCluster

After the operator is running, create a ValkeyCluster custom resource:

```yaml
apiVersion: valkey.io/v1alpha1
kind: ValkeyCluster
metadata:
  name: my-cluster
  namespace: default  # Optional: omit to use current namespace
spec:
  replicas: 3
```

**Note on namespaces:**
- If `manager.watchNamespace` is empty (default), the operator watches all namespaces — you can create ValkeyClusters in any namespace.
- If `manager.watchNamespace` is set, create ValkeyClusters only in that namespace.

Apply the manifest:

```bash
kubectl apply -f cluster.yaml
```

### ValkeyCluster Spec Options

The `spec` field supports:

| Field | Description | Default |
|---|---|---|
| `replicas` | Number of replicas per shard | `3` |
| `shards` | Number of primary shards | *(Not available in all versions)* |
| `mode` | Cluster mode: `standalone` or `replication` | `replication` |
| `persistence.enabled` | Enable persistent storage | `true` |
| `persistence.size` | PVC size | `8Gi` |
| `persistence.storageClass` | Storage class name | *(cluster default)* |
| `failover.enabled` | Automatic failover | `true` |
| `failover.timeoutSeconds` | Failover timeout | `30` |
| `fencing.enabled` | Enable pod fencing | `true` |

Check your installed CRD schema for exact available fields:
```bash
kubectl explain valkeycluster.spec
```

## Observing the Operator

### Check Installation Status

```bash
# Verify operator pod is running
kubectl get pods -n valkey-operator -l app.kubernetes.io/name=valkey-operator

# Check operator logs
kubectl logs -n valkey-operator -l app.kubernetes.io/name=valkey-operator -f
```

### Monitor ValkeyCluster

```bash
# List ValkeyClusters
kubectl get valkeycluster

# Watch a specific cluster
kubectl get valkeycluster my-cluster -w

# Describe for detailed status and events
kubectl describe valkeycluster my-cluster
```

### Inspect ValkeyNodes

```bash
# List all ValkeyNodes
kubectl get valkeynodes

# Get nodes for a specific cluster
kubectl get valkeynodes -l app.kubernetes.io/instance=my-cluster

# Describe a node
kubectl describe valkeynode my-cluster-0
```

### View Metrics

If metrics are enabled:

```bash
# Port-forward the metrics service
kubectl port-forward -n valkey-operator svc/valkey-cluster-metrics 8443:8443 &
sleep 2

# Query Prometheus metrics
curl -k https://localhost:8443/metrics

# Clean up
kill %1
```

Common Prometheus metrics:
- `valkey_operator_reconcile_total` — total reconciliation operations
- `valkey_operator_reconcile_errors_total` — total reconciliation errors
- `valkey_operator_reconcile_duration_seconds` — duration of reconciliations

### Test Valkey Connectivity

```bash
# Get the Valkey service
kubectl get svc -l app.kubernetes.io/instance=my-cluster

# Port-forward to test Redis protocol
kubectl port-forward svc/my-cluster 6379:6379 &
sleep 2

# Ping the Valkey server
redis-cli -h localhost -p 6379 ping

# Clean up
kill %1
```

## Troubleshooting

### Operator pod not starting

```bash
# Check pod status and events
kubectl describe pod -n valkey-operator -l app.kubernetes.io/name=valkey-operator

# Check for image pull errors
kubectl get pods -n valkey-operator -o jsonpath='{.items[*].status.containerStatuses[*].state.waiting.reason}'
```

### ValkeyCluster stuck in Pending

```bash
# Check operator logs for errors
kubectl logs -n valkey-operator -l app.kubernetes.io/name=valkey-operator | grep -i error

# Check PVC provisioning status
kubectl get pvc -l app.kubernetes.io/instance=my-cluster
```

### Metrics unavailable

```bash
# Verify metrics service exists
kubectl get svc -n valkey-operator valkey-cluster-metrics

# Test metrics endpoint directly
kubectl port-forward -n valkey-operator svc/valkey-cluster-metrics 8443:8443 &
curl -k https://localhost:8443/metrics | head -20
```

## Chart Structure

The chart follows standard Helm layout:

```
valkey-operator/
├── Chart.yaml          # Chart metadata
├── values.yaml         # Default configuration values
├── templates/          # Kubernetes manifest templates
│   ├── _helpers.tpl   # Template helper functions
│   ├── deployment.yaml
│   ├── service-account.yaml
│   ├── cluster-role.yaml
│   ├── cluster-role-binding.yaml
│   ├── leader-election-role.yaml
│   ├── leader-election-role-binding.yaml
│   ├── metrics-service.yaml
│   └── NOTES.txt
├── crds/              # Custom Resource Definitions
│   ├── valkeyclusters.yaml
│   └── valkeynodes.yaml
└── README.md          # This documentation
```

### Template File Naming Convention

All template files use lowercase hyphenated multi-word names:
- `service-account.yaml` (not `serviceaccount.yaml`)
- `cluster-role.yaml` (not `clusterrole.yaml`)
- `cluster-role-binding.yaml` (not `clusterrolebinding.yaml`)
- `leader-election-role.yaml`
- `leader-election-role-binding.yaml`

This improves readability and consistency across Kubernetes Helm charts.

## Values Files

Keep a custom `values.yaml` in version control for your production deployment:

```yaml
# Custom production overrides
replicaCount: 2
resources:
  limits:
    cpu: "1"
    memory: "256Mi"
  requests:
    cpu: "250m"
    memory: "128Mi"
metrics:
  enabled: true
```

Apply during install/upgrade:
```bash
helm install valkey-cluster valkey-operator \
  --namespace valkey-operator \
  --values values.yaml
```

## Upgrade and Rollback

```bash
# List release history
helm history valkey-cluster --namespace valkey-operator

# Rollback to previous revision
helm rollback valkey-cluster 1 --namespace valkey-operator
```

## Backup and Restore

### Backing Up Custom Resources

```bash
# Export all ValkeyCluster and ValkeyNode resources
kubectl get valkeycluster --all-namespaces -o yaml > backup-valkeyclusters.yaml
kubectl get valkeynode --all-namespaces -o yaml > backup-valkeynodes.yaml
```

### Restoring After Reinstall

```bash
# Reapply your custom resources
kubectl apply -f backup-valkeyclusters.yaml
kubectl apply -f backup-valkeynodes.yaml
```

## Source Code

- <https://github.com/valkey-io/valkey-operator>

## License

Apache License 2.0 — see the upstream repository for details.
