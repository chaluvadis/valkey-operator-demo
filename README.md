# Valkey Operator Helm Chart

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

A production-ready Helm chart for deploying the **Valkey Operator** on Kubernetes. The operator manages Valkey clusters through custom resources (`ValkeyCluster`, `ValkeyNode`), automating deployment, scaling, failover, and configuration management.

## Overview

This chart deploys the Valkey Operator controller manager as a highly-available Kubernetes Deployment. The operator watches for `ValkeyCluster` custom resources and automatically provisions and manages Valkey clusters including StatefulSets, Services, ConfigMaps, and networking configuration.

### Key Features

- **Automated Cluster Management**: Declarative Valkey cluster provisioning via `ValkeyCluster` CRDs
- **High Availability**: Leader election for multi-replica operator deployments
- **Security Hardened**: Non-root execution, read-only root filesystem, dropped capabilities
- **RBAC Complete**: Least-privilege permissions with ClusterRole and Role separation
- **Observability**: Health probes (liveness/readiness) and Prometheus metrics
- **Flexible Configuration**: Override image, resources, scheduling, and cluster settings
- **Namespace Isolation**: Optional namespace-scoped watching

### Resource Naming

All Kubernetes resources created by this chart use the **release name** as the base identifier:

| Resource | Example (release: `valkey-operator`) |
|----------|--------------------------------------|
| Deployment | `valkey-operator` |
| ServiceAccount | `valkey-operator` |
| ClusterRole | `valkey-operator-manager` |
| ClusterRoleBinding | `valkey-operator-manager` |
| Role (leader election) | `valkey-operator-leader-election` |
| RoleBinding (leader election) | `valkey-operator-leader-election` |
| Service (metrics) | `valkey-operator-metrics` |
| ValkeyCluster | `default-valkey-cluster` (configurable) |
| ValkeyCluster Services | `default-valkey-cluster` (headless) |
| ValkeyCluster StatefulSets | `valkey-default-valkey-cluster-0-{0..N}` |

---

## Prerequisites

- Kubernetes 1.20+
- Helm 3.5+
- Container runtime (Docker, containerd, etc.)

> **Note**: The Valkey Operator requires Custom Resource Definitions (CRDs). This chart includes them but they must be installed separately due to Helm's CRD handling (use `--skip-crds` during Helm install after manual CRD installation).

---

## Quick Start

### 1. Install the CRDs

```bash
kubectl apply -f crds/
```

### 2. Install with Default ValkeyCluster

Deploy the operator **and** create a default ValkeyCluster (1 shard, 3 replicas) with the custom image:

```bash
helm install valkey-operator . \
  --namespace valkey-operator \
  --create-namespace \
  --skip-crds \
  --set image.registry=ghcr.io \
  --set image.repository=chaluvadis/valkey-operator \
  --set image.tag=16d938e \
  --set image.pullPolicy=IfNotPresent \
  --set valkeyCluster.create=true
```

**Result**: A healthy Valkey cluster with 1 shard group and 3 replicas per shard (4 total pods) will be running within ~60 seconds.

After installation, the ValkeyCluster is immediately available — **no manual creation needed**.

### 3. Verify Deployment

```bash
# Check operator is running
kubectl get pods -n valkey-operator

# Check ValkeyCluster status (ready within 1-2 minutes)
kubectl get valkeyclusters -n valkey-operator

# View detailed cluster health
kubectl get valkeycluster default-valkey-cluster -n valkey-operator \
  -o jsonpath='{.status.state}' && echo

# Expected: Ready

# View cluster conditions
kubectl get valkeycluster default-valkey-cluster -n valkey-operator \
  -o jsonpath='{range .status.conditions[*]}{.type}: {.status} - {.reason}{"\n"}{end}'

# View operator logs
kubectl logs -f deployment/valkey-operator -n valkey-operator
```

**Expected Output**:
```
NAME                                      READY   STATUS    RESTARTS   AGE
pod/valkey-default-valkey-cluster-0-0-0   2/2     Running   0          2m
pod/valkey-default-valkey-cluster-0-1-0   2/2     Running   0          2m
pod/valkey-default-valkey-cluster-0-2-0   2/2     Running   0          2m
pod/valkey-default-valkey-cluster-0-3-0   2/2     Running   0          2m
pod/valkey-operator-7bf8b8d9d8-x2k4m      1/1     Running   0          2m

NAME                                             STATE   REASON           AGE
valkeycluster.valkey.io/default-valkey-cluster   Ready   ClusterHealthy   2m

Ready: True (ClusterHealthy) - Cluster is healthy
Progressing: False (ReconcileComplete) - No changes needed
ClusterFormed: True (TopologyComplete) - All nodes joined cluster
SlotsAssigned: True (AllSlotsAssigned) - All slots assigned
```

**Expected Output**:
```
NAME                                      READY   STATUS    RESTARTS   AGE
pod/valkey-default-valkey-cluster-0-0-0   2/2     Running   0          2m
pod/valkey-default-valkey-cluster-0-1-0   2/2     Running   0          2m
pod/valkey-default-valkey-cluster-0-2-0   2/2     Running   0          2m
pod/valkey-default-valkey-cluster-0-3-0   2/2     Running   0          2m
pod/valkey-operator-7bf8b8d9d8-x2k4m      1/1     Running   0          2m

NAME                                             STATE   REASON           AGE
valkeycluster.valkey.io/default-valkey-cluster   Ready   ClusterHealthy   2m
```

---

## Installation Options

### Operator Only (No ValkeyCluster)

Deploy only the operator without creating any ValkeyCluster:

```bash
helm install valkey-operator . \
  --namespace valkey-operator \
  --create-namespace \
  --skip-crds \
  --set valkeyCluster.create=false \
  --set image.registry=ghcr.io \
  --set image.repository=chaluvadis/valkey-operator \
  --set image.tag=16d938e
```

Later, create a ValkeyCluster manually:

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

### Custom ValkeyCluster Configuration

Override the default ValkeyCluster settings:

```bash
helm install valkey-operator . \
  --namespace valkey-operator \
  --create-namespace \
  --skip-crds \
  --set image.registry=ghcr.io \
  --set image.repository=chaluvadis/valkey-operator \
  --set image.tag=16d938e \
  --set valkeyCluster.create=true \
  --set valkeyCluster.name=production-valkey \
  --set valkeyCluster.shards=3 \
  --set valkeyCluster.replicas=2 \
  --set valkeyCluster.resources.limits.cpu=1000m \
  --set valkeyCluster.resources.limits.memory=1Gi
```

### Using a Custom values.yaml

```bash
helm install valkey-operator . \
  --namespace valkey-operator \
  --create-namespace \
  --skip-crds \
  --values values-production.yaml
```

Example `values-production.yaml`:
```yaml
replicaCount: 2

image:
  registry: ghcr.io
  repository: chaluvadis/valkey-operator
  tag: 16d938e
  pullPolicy: IfNotPresent

valkeyCluster:
  create: true
  name: production-valkey
  shards: 6
  replicas: 2
  resources:
    limits:
      cpu: 2000m
      memory: 2Gi
    requests:
      cpu: 1000m
      memory: 1Gi

resources:
  limits:
    cpu: 1000m
    memory: 512Mi
  requests:
    cpu: 500m
    memory: 256Mi
```

---

## Configuration Parameters

The following table lists the configurable parameters of the Valkey Operator chart and their default values.

### Global Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of operator replicas | `1` |
| `namespace` | Target namespace for deployment | `valkey-operator` |

### Image Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.registry` | Container image registry | `ghcr.io` |
| `image.repository` | Container image repository | `chaluvadis/valkey-operator` |
| `image.tag` | Container image tag | `""` (uses chart `appVersion`) |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |

### ValkeyCluster Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `valkeyCluster.create` | Create a ValkeyCluster resource | `true` |
| `valkeyCluster.name` | Name of the ValkeyCluster | `"default-valkey-cluster"` |
| `valkeyCluster.shards` | Number of shard groups | `1` |
| `valkeyCluster.replicas` | Replicas per shard group | `3` |
| `valkeyCluster.resources` | Resource limits/requests per node | `See values.yaml` |
| `valkeyCluster.nodeSelector` | Node selection constraints | `{}` |
| `valkeyCluster.tolerations` | Pod tolerations | `[]` |
| `valkeyCluster.affinity` | Pod affinity rules | `{}` |

### RBAC Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `rbac.create` | Create ClusterRole and ClusterRoleBinding | `true` |

### ServiceAccount Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceAccount.create` | Create a new ServiceAccount | `true` |
| `serviceAccount.name` | Name of the ServiceAccount (auto-generated if empty) | `""` |

### Manager Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `manager.leaderElection.enabled` | Enable leader election for HA | `true` |
| `manager.watchNamespace` | Namespace to watch (empty = all) | `""` |
| `manager.args` | Additional CLI arguments for the operator | `[]` |

### Metrics Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `metrics.enabled` | Enable metrics endpoint | `true` |
| `metrics.port` | Metrics port | `8443` |
| `metrics.service.type` | Service type for metrics | `ClusterIP` |

### Resource Limits (Operator Container)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `128Mi` |
| `resources.requests.cpu` | CPU request | `10m` |
| `resources.requests.memory` | Memory request | `64Mi` |

### Security Contexts

| Parameter | Description | Default |
|-----------|-------------|---------|
| `podSecurityContext.runAsNonRoot` | Run as non-root user | `true` |
| `podSecurityContext.seccompProfile.type` | Seccomp profile | `RuntimeDefault` |
| `securityContext.readOnlyRootFilesystem` | Read-only root filesystem | `true` |
| `securityContext.allowPrivilegeEscalation` | Allow privilege escalation | `false` |
| `securityContext.capabilities.drop` | Linux capabilities to drop | `[ALL]` |

### Scheduling Constraints

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nodeSelector` | Node labels for pod assignment | `{}` |
| `tolerations` | Pod tolerations | `[]` |
| `affinity` | Pod affinity rules | `{}` |

---

## ValkeyCluster Spec Options

The Helm chart **automatically creates a default ValkeyCluster** named `default-valkey-cluster` during installation. No manual creation is needed for the default cluster.

To create **additional** ValkeyClusters, create new `ValkeyCluster` custom resources. The following fields are supported (based on the installed CRD):

```yaml
apiVersion: valkey.io/v1alpha1
kind: ValkeyCluster
metadata:
  name: my-cluster
  namespace: valkey-operator
spec:
  shards: 3              # Number of primary shard groups
  replicas: 2            # Number of replicas per shard
  image: valkey:7.2      # Override default Valkey image (optional)
  
  # Resource requirements for each Valkey node
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 100m
      memory: 256Mi
  
  # Node selection
  nodeSelector:
    kubernetes.io/os: linux
  
  # Tolerations
  tolerations:
    - key: "node-role.kubernetes.io/control-plane"
      operator: "Exists"
      effect: "NoSchedule"
  
  # Affinity rules
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            topologyKey: kubernetes.io/hostname
            labelSelector:
              matchExpressions:
                - key: app.kubernetes.io/name
                  operator: In
                  values:
                    - valkey
  
  # TLS configuration (optional)
  tls:
    certificate:
      secretName: valkey-tls-secret
  
  # Additional configuration parameters
  config:
    maxmemory-policy: allkeys-lru
    save: ""
```

### Query Available Fields

```bash
kubectl explain valkeycluster.spec
kubectl explain valkeycluster.spec.shards
kubectl explain valkeycluster.spec.resources
```

---

## Observability

### Health Checks

The operator exposes the following endpoints:

- **Liveness Probe**: `GET /healthz` on port 8081
- **Readiness Probe**: `GET /readyz` on port 8081
- **Metrics**: `GET /metrics` on port 8443 (TLS)

### View Operator Logs

```bash
# Stream operator logs
kubectl logs -f deployment/valkey-operator -n valkey-operator

# View Valkey node logs
kubectl logs -f statefulset/valkey-default-valkey-cluster-0-0 -n valkey-operator -c valkey
```

### Prometheus Metrics

When metrics are enabled (`metrics.enabled: true`), the operator exposes Prometheus metrics on port 8443.

```bash
# Port-forward metrics service
kubectl port-forward -n valkey-operator svc/valkey-operator-metrics 8443:8443

# Query metrics
curl -k https://localhost:8443/metrics
```

Common metrics:
- `valkey_operator_reconcile_total` — Total reconciliation operations
- `valkey_operator_reconcile_errors_total` — Total reconciliation errors
- `valkey_operator_reconcile_duration_seconds` — Reconciliation duration
- `valkey_operator_valkeycluster_status{condition}` — Cluster status conditions

### Monitoring ValkeyCluster

```bash
# List all ValkeyClusters
kubectl get valkeyclusters -n valkey-operator

# Watch cluster status
kubectl get valkeycluster default-valkey-cluster -n valkey-operator -w

# Describe for detailed status and events
kubectl describe valkeycluster default-valkey-cluster -n valkey-operator

# Check cluster conditions
kubectl get valkeycluster default-valkey-cluster -n valkey-operator \
  -o jsonpath='{range .status.conditions[*]}{.type}: {.status} ({.reason}) - {.message}{"\n"}{end}'

# View ValkeyNodes
kubectl get valkeynodes -n valkey-operator -l valkey.io/cluster=default-valkey-cluster
```

---

## Testing Valkey Connectivity

```bash
# Method 1: Using kubectl exec
kubectl exec -it -n valkey-operator \
  statefulset/valkey-default-valkey-cluster-0-0 \
  -- valkey-cli -h localhost -p 6379 ping

# Method 2: Using a temporary pod
kubectl run -it --rm valkey-client \
  --image=valkey/valkey:latest \
  -n valkey-operator \
  --restart=Never \
  -- valkey-cli -h default-valkey-cluster -p 6379 ping

# Method 3: Port-forward and use redis-cli
kubectl port-forward -n valkey-operator \
  svc/default-valkey-cluster 6379:6379 &
sleep 2
redis-cli -h localhost -p 6379 ping
kill %1
```

**Expected Response**: `PONG`

---

## Troubleshooting

### Operator Pod Not Starting

```bash
# Check pod status and events
kubectl describe pod -n valkey-operator -l app.kubernetes.io/name=valkey-operator

# Check for image pull errors
kubectl get pods -n valkey-operator -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[0].state.waiting.reason}{"\n"}{end}'

# Check resource availability
kubectl describe nodes | grep -A 5 "Allocated resources"
```

**Solution**: 
- Verify image name and tag
- Ensure node has sufficient resources
- Check network connectivity to image registry

### ValkeyCluster Stuck in "UpdatingNodes" or "Reconciling"

```bash
# Check operator logs for errors
kubectl logs -n valkey-operator deployment/valkey-operator | grep -i error

# Check ValkeyNode status
kubectl get valkeynodes -n valkey-operator
kubectl describe valkeynode <node-name> -n valkey-operator

# Check StatefulSet status
kubectl get statefulsets -n valkey-operator
kubectl describe statefulset <sts-name> -n valkey-operator

# Check PVCs (if persistence is used)
kubectl get pvc -n valkey-operator
```

**Common Causes**:
- Insufficient resources on nodes
- Network policies blocking pod-to-pod communication
- Missing or invalid ConfigMaps
- RBAC permissions issues

### Valkey Nodes CrashLoopBackOff

```bash
# Check container logs
kubectl logs -n valkey-operator <pod-name> -c valkey

# Check init container logs
kubectl logs -n valkey-operator <pod-name> -c init-scripts

# Describe the pod
kubectl describe pod -n valkey-operator <pod-name>
```

**Common Causes**:
- Invalid Valkey configuration
- Port conflicts
- Insufficient memory
- Corrupted data directory

### Metrics Unavailable

```bash
# Verify metrics service exists
kubectl get svc -n valkey-operator valkey-operator-metrics

# Check if metrics port is listening
kubectl exec -n valkey-operator deployment/valkey-operator -- netstat -tlnp | grep 8443

# Test metrics endpoint directly
kubectl port-forward -n valkey-operator svc/valkey-operator-metrics 8443:8443 &
curl -k https://localhost:8443/metrics 2>&1
kill %1
```

**Solution**: 
- Verify `metrics.enabled: true` in values
- Check firewall/network policies
- Ensure TLS certificates are valid (if using TLS)

### Certificate/TLS Issues

```bash
# Check TLS secret exists
kubectl get secret -n valkey-operator valkey-tls-secret

# Verify secret contents
kubectl get secret -n valkey-operator valkey-tls-secret -o jsonpath='{.data}' | jq
```

**Solution**:
- Ensure TLS secret contains `ca.crt`, `tls.crt`, and `tls.key`
- Verify certificate validity and CN/SANs
- Check certificate expiration

---

## Chart Structure

```
valkey-operator/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default configuration values
├── .helmignore             # Helm ignore patterns
├── crds/                   # Custom Resource Definitions
│   ├── valkeyclusters.yaml
│   └── valkeynodes.yaml
├── templates/              # Kubernetes manifest templates
│   ├── _helpers.tpl       # Template helper functions
│   ├── deployment.yaml    # Operator Deployment
│   ├── serviceaccount.yaml
│   ├── cluster-role.yaml
│   ├── cluster-role-binding.yaml
│   ├── leader-election-role.yaml
│   ├── leader-election-role-binding.yaml
│   ├── metrics-service.yaml
│   ├── valkeycluster.yaml # ValkeyCluster resource
│   └── NOTES.txt          # Post-installation notes
└── README.md               # This file
```

### Template Naming Convention

All template files use **lowercase hyphenated multi-word names**:
- `service-account.yaml` (not `serviceaccount.yaml`)
- `cluster-role.yaml` (not `clusterrole.yaml`)
- `leader-election-role-binding.yaml` (not `leaderElectionRoleBinding.yaml`)

This follows the [Helm chart best practices](https://helm.sh/docs/topics/chart_best_practices/) for consistency across Kubernetes projects.

---

## Upgrading

### Upgrade the Operator

```bash
# Review changes before upgrading
helm diff upgrade valkey-operator . \
  --namespace valkey-operator \
  --skip-crds \
  --set image.tag=<new-tag>

# Perform upgrade
helm upgrade valkey-operator . \
  --namespace valkey-operator \
  --skip-crds \
  --set image.tag=<new-tag>
```

### Rollback

```bash
# List release history
helm history valkey-operator --namespace valkey-operator

# Rollback to previous revision
helm rollback valkey-operator <revision> --namespace valkey-operator
```

### CRD Updates

When updating the CRD definitions:

```bash
# Backup existing resources
kubectl get valkeyclusters --all-namespaces -o yaml > backup-valkeyclusters.yaml
kubectl get valkeynodes --all-namespaces -o yaml > backup-valkeynodes.yaml

# Update CRDs
kubectl apply -f crds/

# Restore resources (if needed)
kubectl apply -f backup-valkeyclusters.yaml
kubectl apply -f backup-valkeynodes.yaml
```

> **Warning**: CRD updates can cause temporary unavailability of Valkey clusters. Test in non-production first.

---

## Backup and Restore

### Backing Up ValkeyCluster Resources

```bash
# Export all ValkeyCluster definitions
kubectl get valkeyclusters --all-namespaces -o yaml > backup-valkeyclusters.yaml

# Export all ValkeyNode definitions
kubectl get valkeynodes --all-namespaces -o yaml > backup-valkeynodes.yaml

# Export operator configuration
kubectl get configmap,secret -n valkey-operator -l app.kubernetes.io/name=valkey-operator \
  -o yaml > backup-operator-config.yaml
```

### Restoring After Reinstall

```bash
# Reinstall CRDs
kubectl apply -f crds/

# Reinstall operator
helm install valkey-operator . \
  --namespace valkey-operator \
  --create-namespace \
  --skip-crds \
  --set valkeyCluster.create=false

# Restore ValkeyCluster resources
kubectl apply -f backup-valkeyclusters.yaml

# Restore ValkeyNode resources
kubectl apply -f backup-valkeynodes.yaml
```

> **Note**: This backs up only the ValkeyCluster manifests, not the actual Valkey data. For data backup, use [Valkey persistence](https://redis.io/docs/latest/operate/rs/databases/persistence/) (RDB/AOF) or [replication](https://redis.io/docs/latest/operate/rs/databases/replication/).

---

## Security

### Security Context

The operator and Valkey nodes run with strict security contexts:

```yaml
# Pod-level
runAsNonRoot: true
seccompProfile:
  type: RuntimeDefault

# Container-level
readOnlyRootFilesystem: true
allowPrivilegeEscalation: false
capabilities:
  drop:
    - ALL
```

### Network Policies

Optional NetworkPolicy support is included:

```yaml
networkPolicy:
  enabled: true
  targetNamespace: ""  # Set to Valkey cluster namespace
  podSelector:
    matchLabels:
      app.kubernetes.io/name: valkey
  port: 6379
```

Enable to restrict traffic to Valkey pods to only authorized namespaces.

### RBAC

The operator uses least-privilege RBAC:

- **ClusterRole**: Cluster-scoped permissions for CRD discovery and namespace listing
- **Role**: Namespace-scoped permissions for managing ValkeyCluster resources
- **RoleBinding**: Ties Role to ServiceAccount
- **ClusterRoleBinding**: Ties ClusterRole to ServiceAccount

---

## Production Recommendations

### High Availability

```yaml
# Run multiple operator replicas
replicaCount: 2

# Enable leader election (default)
manager:
  leaderElection:
    enabled: true

# Add pod anti-affinity for Valkey nodes
valkeyCluster:
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

### Resource Management

```yaml
# Define resource limits for Valkey nodes
valkeyCluster:
  resources:
    limits:
      cpu: 2000m
      memory: 4Gi
    requests:
      cpu: 1000m
      memory: 2Gi

# Set node selectors for dedicated nodes
  nodeSelector:
    node-role.kubernetes.io/worker: "true"
    hardware: high-memory
```

### Monitoring

1. **Prometheus Operator**: Deploy `ServiceMonitor`
2. **Grafana**: Import Valkey dashboard (port 8443)
3. **Alerts**: Configure on `valkey_operator_reconcile_errors_total`

### Backup Strategy

- Enable Valkey [AOF persistence](https://redis.io/docs/latest/operate/rs/databases/persistence/)
- Schedule regular RDB snapshots
- Use `kubectl get valkeycluster -o yaml` for cluster configuration backup
- Consider [Velero](https://velero.io/) for full cluster backup

---

## Development

### Local Testing

```bash
# Render templates locally
helm template test . --namespace test --skip-crds

# Validate with kubeconform
helm template test . --skip-crds | kubeconform -strict -summary

# Lint chart
helm lint .
```

### Running Tests

```bash
# Execute chart tests (if defined)
helm test valkey-operator --namespace valkey-operator
```

---

## Troubleshooting FAQ

**Q: Why does the ValkeyCluster stay in "UpdatingNodes" state?**

A: This typically indicates pods are failing to start. Check:
- Node resource availability (`kubectl describe nodes`)
- Image pull secrets (`kubectl get secrets`)
- Network policies (`kubectl get networkpolicies`)
- Node selector/taint tolerations

**Q: Can I run multiple ValkeyOperator instances?**

A: Yes, but each must watch different namespaces to avoid conflicts. Set `manager.watchNamespace` to isolate scopes.

**Q: How do I change the Valkey version?**

A: Set `valkeyCluster.image` in your values or use `kubectl edit valkeycluster <name>` to update the spec.

**Q: Why is the operator using high CPU?**

A: High reconciliation frequency can occur if:
- Cluster is under heavy load
- Many configuration changes are happening
- Nodes are frequently failing/restarting
Check operator logs for reconciliation loops.

**Q: Can I disable the default ValkeyCluster?**

A: Yes. Set `valkeyCluster.create=false` during installation or upgrade.

---

## Support

- **Issues**: [GitHub Issues](https://github.com/valkey-io/valkey-operator/issues)
- **Documentation**: [Valkey Operator Docs](https://github.com/valkey-io/valkey-operator)
- **Community**: [Valkey Slack](https://valkey.io/slack)

## License

This Helm chart is licensed under the Apache License 2.0. See [LICENSE](./LICENSE) for details.

The Valkey Operator is a [CNCF](https://www.cncf.io/) project.

---

**Last Updated**: 2026-05-05
**Chart Version**: 0.1.0
**App Version**: 16d938e (Valkey Operator)