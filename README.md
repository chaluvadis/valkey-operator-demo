# Valkey Infrastructure Umbrella Chart

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

A production-grade **umbrella Helm chart** for deploying the complete Valkey platform on Kubernetes. This chart orchestrates the **Valkey Operator** (control plane) and **ValkeyCluster** (data plane) as loosely coupled subcharts with safe installation order.

## Architecture

```
valkey-infra/                    (Umbrella Chart - Single entrypoint)
├── Chart.yaml                  # Declares dependencies: valkey-operator + valkey-cluster
├── values.yaml                 # Centralized configuration for both components
├── crds/                       # Custom Resource Definitions (installed once globally)
│   ├── valkeyclusters.yaml
│   └── valkeynodes.yaml
└── charts/                     # Subchart dependencies
    ├── valkey-operator/        # Control plane - Kubernetes operator
    └── valkey-cluster/         # Data plane - ValkeyCluster custom resource
```

### Component Separation

| Subchart          | Role          | Installs                                           |
| ----------------- | ------------- | -------------------------------------------------- |
| `valkey-operator` | Control plane | Operator Deployment, RBAC, ServiceAccount, Metrics |
| `valkey-cluster`  | Data plane    | `ValkeyCluster` custom resource only               |

## Prerequisites

- Kubernetes 1.20+
- Helm 3.5+

## Quick Start

### 0. Install the CRDs First

```bash
  kubectl apply -f crds/
```

CRDs are cluster-scoped, not namespace-scoped, so -n valkey-operator has no effect for them.

### 1. Install the Umbrella Chart

This single command installs **both** the operator and a default ValkeyCluster:

```bash
helm install valkey-infra . \
  --namespace valkey-operator \
  --create-namespace \
  --skip-crds
```

**What happens:**

1. CRDs (`ValkeyCluster`, `ValkeyNode`) are installed (once per cluster)
2. `valkey-operator` subchart deploys the operator
3. Operator becomes ready (health checks pass)
4. `valkey-cluster` subchart creates the `ValkeyCluster` custom resource
5. Operator reconciles the cluster to running state

### 2. Verify Installation

```bash
# Check operator pod
kubectl get pods -n valkey-operator -l app.kubernetes.io/name=valkey-operator

# Check ValkeyCluster status
kubectl get valkeyclusters -n valkey-operator

# Check Valkey nodes (StatefulSet pods)
kubectl get statefulsets -n valkey-operator
kubectl get pods -n valkey-operator -l app.kubernetes.io/name=valkey
```

## Installation Options

### Operator-Only Mode

Deploy only the operator without any ValkeyCluster:

```bash
helm install valkey-infra . \
  --namespace valkey-operator \
  --create-namespace \
  --skip-crds \
  --set cluster.enabled=false
```

Create ValkeyClusters manually afterward:

```yaml
apiVersion: valkey.io/v1alpha1
kind: ValkeyCluster
metadata:
  name: my-cluster
  namespace: valkey-operator
spec:
  shards: 3
  replicas: 2
```

### Custom Cluster Configuration

Override cluster settings via values:

```bash
helm install valkey-infra . \
  --namespace valkey-operator \
  --create-namespace \
  --skip-crds \
  --set cluster.name=production-db \
  --set cluster.shards=6 \
  --set cluster.replicas=3 \
  --set cluster.image.repository=valkey/valkey \
  --set cluster.image.tag=7.2-alpine \
  --set cluster.resources.limits.memory=4Gi
```

### Using a Custom values.yaml

```bash
helm install valkey-infra . \
  --namespace valkey-operator \
  --create-namespace \
  --skip-crds \
  --values values-production.yaml
```

Example `values-production.yaml`:

```yaml
operator:
  replicaCount: 2
  image:
    tag: v1.0.0
  resources:
    limits:
      cpu: 1000m
      memory: 256Mi

cluster:
  name: production-valkey
  shards: 6
  replicas: 2
  image:
    tag: 7.2-alpine
  resources:
    limits:
      cpu: 2000m
      memory: 4Gi
```

## Configuration Reference

### Global Settings

| Parameter                 | Description                     | Default |
| ------------------------- | ------------------------------- | ------- |
| `global.imageRegistry`    | Override global Docker registry | `""`    |
| `global.imagePullSecrets` | List of image pull secret names | `[]`    |

### Operator Settings (`operator.*`)

| Parameter                                 | Description                           | Default                      |
| ----------------------------------------- | ------------------------------------- | ---------------------------- |
| `operator.replicaCount`                   | Number of operator replicas (HA)      | `1`                          |
| `operator.image.repository`               | Operator container image              | `valkey-io/valkey-operator`  |
| `operator.image.tag`                      | Operator image tag                    | `""` (uses chart appVersion) |
| `operator.image.pullPolicy`               | Image pull policy                     | `IfNotPresent`               |
| `operator.rbac.create`                    | Create ClusterRole/ClusterRoleBinding | `true`                       |
| `operator.serviceAccount.create`          | Create ServiceAccount                 | `true`                       |
| `operator.manager.leaderElection.enabled` | Enable leader election for HA         | `true`                       |
| `operator.metrics.enabled`                | Enable Prometheus metrics endpoint    | `true`                       |
| `operator.resources`                      | Operator container resources          | See values.yaml              |

See `charts/valkey-operator/values.yaml` for full operator configuration options.

### Cluster Settings (`cluster.*`)

| Parameter                           | Description                       | Default          |
| ----------------------------------- | --------------------------------- | ---------------- |
| `cluster.enabled`                   | Enable/disable cluster creation   | `true`           |
| `cluster.name`                      | ValkeyCluster resource name       | `valkey-cluster` |
| `cluster.replicas`                  | Replicas per shard                | `1`              |
| `cluster.shards`                    | Number of shard groups            | `3`              |
| `cluster.image.repository`          | Valkey container image            | `valkey/valkey`  |
| `cluster.image.tag`                 | Valkey image tag                  | `7.2-alpine`     |
| `cluster.resources`                 | Valkey node resources             | See values.yaml  |
| `cluster.dataStorage.enabled`       | Enable persistent storage         | `false`          |
| `cluster.dataStorage.requestedSize` | PVC size when persistence enabled | `5Gi`            |

See `charts/valkey-cluster/values.yaml` for full cluster configuration options (nodeSelector, tolerations, affinity, TLS, etc.).

## Safe Installation Order & Race Condition Handling

The umbrella chart enforces **correct lifecycle ordering**:

1. **CRDs** are installed first (via `helm install --skip-crds` pattern or automatically)
2. **Operator** subchart installs first (dependency order)
3. **Cluster** subchart installs second (depends on operator being ready)

Kubernetes reconciliation ensures the operator is running before processing the `ValkeyCluster` resource. No sleep hacks or timing-based logic needed.

## Upgrading

### Safe Upgrade Practices

Before any upgrade:

- Always backup existing ValkeyCluster resources: `kubectl get valkeyclusters --all-namespaces -o yaml > backup.yaml`
- Test upgrades in a staging environment first
- Review release notes for breaking changes
- Use `--dry-run` to preview changes: `helm upgrade valkey-infra . --skip-crds --dry-run`

### Upgrade Operator Only

```bash
helm upgrade valkey-infra . \
  --skip-crds \
  --set operator.image.tag=v1.0.0
```

### Upgrade Cluster Configuration

```bash
helm upgrade valkey-infra . \
  --skip-crds \
  --set cluster.shards=6 \
  --set cluster.replicas=3
```

### CRD Updates

CRDs are managed separately. When updating CRDs:

```bash
# Backup existing resources (CRITICAL STEP)
kubectl get valkeyclusters --all-namespaces -o yaml > backup-clusters.yaml
kubectl get valkeynodes --all-namespaces -o yaml > backup-nodes.yaml

# Apply new CRDs
kubectl apply -f valkey-infra/crds/

# Reinstall operator (without touching clusters)
helm upgrade valkey-infra . --skip-crds --set cluster.enabled=false

# Verify clusters are still present after CRD update
kubectl get valkeyclusters --all-namespaces
```

## Rollback

```bash
# List release history
helm history valkey-infra --namespace valkey-operator

# Rollback to previous revision
helm rollback valkey-infra <revision>
```

## Uninstall

### Safe Uninstall Practices

Before uninstalling:

- Always backup existing ValkeyCluster resources: `kubectl get valkeyclusters --all-namespaces -o yaml > backup.yaml`
- Consider scaling down clusters to zero replicas first if you want to preserve data
- Verify no applications are depending on the Valkey clusters

### Remove Release (Preserves CRDs and Data)

```bash
# Remove the Helm release but keep CRDs and existing ValkeyCluster resources
helm uninstall valkey-infra --namespace valkey-operator
```

### Complete Removal (Deletes Everything)

```bash
# 1. Backup all Valkey resources (RECOMMENDED)
kubectl get valkeyclusters --all-namespaces -o yaml > backup-clusters.yaml
kubectl get valkeynodes --all-namespaces -o yaml > backup-nodes.yaml

# 2. Optionally scale down clusters to zero before deletion (for persistence)
# kubectl patch valkeycluster/<name> -n <namespace> -p '{"spec":{"replicas":0}}' --type=merge

# 3. Remove the Helm release
helm uninstall valkey-infra --namespace valkey-operator

# 4. Delete CRDs (THIS DELETES ALL VALKEYCLUSTER RESOURCES!)
kubectl delete crd valkeyclusters.valkey.io
kubectl delete crd valkeynodes.valkey.io
```

### Selective Removal

To remove only the operator while keeping ValkeyCluster resources:

```bash
helm upgrade valkey-infra . --skip-crds --set cluster.enabled=false
```

To remove ValkeyCluster resources but keep the operator for future use:

```bash
# Delete specific ValkeyCluster resources
kubectl delete valkeycluster <cluster-name> -n <namespace>

# Or delete all ValkeyClusters in a namespace
kubectl delete valkeycluster --all -n <namespace>
```

## Multi-Cluster Support

Deploy multiple independent Valkey clusters in different namespaces:

```bash
# Cluster 1 in namespace db-prod
helm install valkey-infra . \
  --namespace db-prod \
  --create-namespace \
  --set cluster.name=prod-primary \
  --set cluster.shards=6

# Cluster 2 in namespace db-staging
helm install valkey-infra . \
  --namespace db-staging \
  --create-namespace \
  --set cluster.name=staging \
  --set cluster.shards=1
```

Each namespace gets its own isolated ValkeyCluster managed by the same operator.

## High Availability (HA)

```yaml
operator:
  replicaCount: 3
  manager:
    leaderElection:
      enabled: true

cluster:
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchExpressions:
              - key: app.kubernetes.io/name
                operator: In
                values:
                  - valkey
          topologyKey: kubernetes.io/hostname
```

## Monitoring

### Metrics

Operator exposes Prometheus metrics on port 8443:

```bash
kubectl port-forward -n valkey-operator svc/valkey-operator-metrics 8443:8443
curl -k https://localhost:8443/metrics
```

Key metrics:

- `valkey_operator_reconcile_total` — Reconciliation operations
- `valkey_operator_reconcile_errors_total` — Reconciliation errors
- `valkey_operator_valkeycluster_status{condition}` — Cluster health

## Troubleshooting

### Operator Not Ready

```bash
kubectl describe pod -n valkey-operator -l app.kubernetes.io/name=valkey-operator
kubectl logs -n valkey-operator deployment/valkey-operator
```

Check for:

- Image pull errors
- RBAC restrictions (missing ClusterRole)
- Insufficient resources

### ValkeyCluster Stuck

```bash
kubectl get valkeycluster -n valkey-operator
kubectl describe valkeycluster <name> -n valkey-operator
kubectl get valkeynodes -n valkey-operator -l valkey.io/cluster=<name>
```

Common causes:

- Operator not ready (wait forReady)
- Resource quotas exceeded
- Network policies blocking pod-to-pod traffic

### PVCs Not Binding (when persistence enabled)

```bash
kubectl get pvc -n valkey-operator
kubectl describe pvc <name> -n valkey-operator
```

Verify storage class exists and has available capacity.

## Development

### Render Manifests

```bash
helm template valkey-infra . --skip-crds
```

### Lint Charts

```bash
helm lint charts/valkey-operator
helm lint charts/valkey-cluster
helm dependency update valkey-infra && helm lint valkey-infra
```

### Test Installation Locally

```bash
helm install valkey-infra . --namespace test --create-namespace --skip-crds --dry-run
```

## Design Decisions

### Why Umbrella Chart?

- **Single source of truth**: One Helm release manages full stack
- **Deterministic ordering**: Operator always installed before clusters
- **Centralized config**: Global values in one place
- **CRUD lifecycle**: Full stack install/upgrade/rollback as unit
- **Production-ready**: Follows Kubernetes operator best practices

### Why Not Coupled?

- **Independent subcharts**: Operator can be deployed standalone
- **Separate versioning**: Each subchart can evolve independently
- **No cross-chart hacks**: No sleep/retry in templates
- **Clean separation**: Control plane vs data plane concerns

## License

Apache License 2.0
