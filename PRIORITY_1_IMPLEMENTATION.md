# Priority 1 Implementation: Kubernetes Cluster Resource Optimization

**Date:** 2026-04-04  
**Issue:** #64 - Kubernetes Cluster Resource Optimization  
**Status:** In Progress

## Overview

This document tracks the implementation of Priority 1 actions from Issue #64:
1. Set resource limits on ArgoCD components
2. Set resource limits on Prometheus
3. Reduce CPU limits by 20% to create headroom

## Changes Made

### 1. ArgoCD Helm Chart Creation

Created a new Helm chart at `k8s/charts/argocd/` with resource limits for all ArgoCD components:

**Chart Structure:**
- `Chart.yaml` - Chart metadata (v1.0.0, ArgoCD 2.10.3)
- `values.yaml` - Resource limits configuration
- `templates/namespace.yaml` - ArgoCD namespace
- `templates/configmap.yaml` - ArgoCD command parameters (server insecure mode)
- `templates/patches.yaml` - Resource limit patches for all components

**Resource Limits Applied:**
| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|------------|-----------|----------------|--------------|
| application-controller | 100m | 500m | 256Mi | 512Mi |
| repo-server | 50m | 200m | 64Mi | 256Mi |
| server | 25m | 200m | 64Mi | 256Mi |
| applicationset-controller | 25m | 100m | 64Mi | 128Mi |
| notifications-controller | 25m | 100m | 64Mi | 128Mi |
| dex-server | 25m | 100m | 64Mi | 128Mi |
| redis | 10m | 50m | 32Mi | 64Mi |

**Total ArgoCD Limits:** 1250m CPU, 1280Mi Memory

**Note:** The patches template provides strategic merge patches that will be applied to existing ArgoCD deployments. These patches assume the official ArgoCD v2.10.3 manifests are already applied.

**ArgoCD Application:** `k8s/argocd/applications/argocd.yaml`
- Managed by home-lab root application
- Namespace: argocd
- Sync wave: 0 (earliest)

### 2. Prometheus Resource Limits

Updated `k8s/charts/prometheus/values.yaml` with resource limits:

**Resource Limits Applied:**
| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|------------|-----------|----------------|--------------|
| prometheus | 100m | 500m | 512Mi | 1Gi |

**Note:** Created `templates/prometheus-patch.yaml` to patch the `prometheus-kube-prometheus-stack-prometheus` StatefulSet with these limits.

### 3. CPU Limit Reduction (20% Headroom)

Reduced CPU limits across all application charts by 20% to create cluster headroom:

| Application | Original Limit | New Limit | Reduction |
|-------------|----------------|-----------|-----------|
| applications | 1000m | 800m | 200m |
| influxdb | 500m | 400m | 100m |
| postgres | 500m | 400m | 100m |
| dns | 500m | 400m | 100m |
| wikijs | 500m | 400m | 100m |
| frontend | 500m | 400m | 100m |
| anki | 500m | 400m | 100m |

**Total CPU Reduction:** 1100m (17.6%)

**New Total CPU Limits:** ~5150m (reduced from ~6250m)
- This provides approximately 25% headroom below the 4-core (4000m) node capacity after accounting for system pods

## Files Modified

```
k8s/charts/argocd/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── namespace.yaml
│   ├── configmap.yaml
│   └── patches.yaml

k8s/charts/prometheus/
├── values.yaml
└── templates/
    └── prometheus-patch.yaml

k8s/charts/applications/values.yaml        # CPU: 1000m → 800m
k8s/charts/influxdb/values.yaml           # CPU: 500m → 400m
k8s/charts/postgres/values.yaml           # CPU: 500m → 400m
k8s/charts/dns/values.yaml                # CPU: 500m → 400m
k8s/charts/wikijs/values.yaml             # CPU: 500m → 400m
k8s/charts/frontend/values.yaml           # CPU: 500m → 400m
k8s/charts/anki/values.yaml               # CPU: 500m → 400m

k8s/argocd/applications/argocd.yaml       # New: ArgoCD Application
```

## Implementation Notes

### ArgoCD Deployment Strategy

The current ArgoCD installation uses the official manifests from:
```
https://raw.githubusercontent.com/argoproj/argo-cd/v2.10.3/manifests/install.yaml
```

The new ArgoCD Helm chart provides:
1. **Namespace Management** - Ensures argocd namespace exists
2. **Configuration** - ConfigMap for server insecure mode
3. **Resource Patches** - Strategic merge patches for all components

**Deployment Steps:**
1. Install the official ArgoCD manifests (already done via `k8s/argocd/setup/install.yaml`)
2. Apply the new ArgoCD Application to deploy the Helm chart
3. The patches will update existing deployments with resource limits

### Prometheus Patch Strategy

Similar to ArgoCD, the Prometheus patch targets the `prometheus-kube-prometheus-stack-prometheus` StatefulSet created by the `kube-prometheus-stack` Helm chart.

**Deployment Steps:**
1. Ensure kube-prometheus-stack is installed
2. Apply the Prometheus chart updates via ArgoCD
3. The patches will update the existing StatefulSet with resource limits

## Next Steps

### For Completion:
1. Test the ArgoCD application deployment
2. Verify resource limits are applied to running pods
3. Monitor cluster resource utilization after deployment
4. Update monitoring dashboards to show headroom metrics

### Priority 2 (Next):
- Set resource limits on system pods (coredns, traefik, metrics-server)
- Add memory alerts at 80% threshold
- Review and reduce memory requests for over-allocated pods

## Verification Commands

```bash
# Verify ArgoCD application
kubectl get application -n argocd argocd

# Check ArgoCD pod resource limits
kubectl get pods -n argocd -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].resources}{"\n"}{end}'

# Check Prometheus resource limits
kubectl get statefulset -n default prometheus-kube-prometheus-stack-prometheus -o jsonpath='{.spec.template.spec.containers[*].resources}'

# Monitor overall cluster resource usage
kubectl top nodes
kubectl top pods -A
```

## References

- **Issue:** #64 - Kubernetes Cluster Resource Optimization
- **Analysis:** `KUBERNETES_RESOURCE_ANALYSIS.md`
- **ArgoCD Docs:** https://argo-cd.readthedocs.io/
- **Kubernetes Resource Management:** https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
