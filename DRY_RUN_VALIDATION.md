# Priority 1 Implementation: Dry-Run Validation Report

**Date:** 2026-04-04  
**Status:** ✅ ALL VALIDATIONS PASSED

## Executive Summary

✓ All Kubernetes manifests validated and pass `kubectl apply --dry-run=client`  
✓ Helm templates render without errors  
✓ ArgoCD Application resource valid  
✓ Total CPU allocation: **3000m** (75% of node capacity)  
✓ Cluster headroom: **1000m** (25% for burstable workloads)

## Validation Results

### Chart Templates - All Passing ✓

| Chart | Resources | Validation |
|-------|-----------|-----------|
| argocd | 9 | ✓ PASS |
| prometheus | 2 | ✓ PASS |
| applications | 8 | ✓ PASS |
| influxdb | 7 | ✓ PASS |
| postgres | 4 | ✓ PASS |
| dns | 7 | ✓ PASS |
| wikijs | 4 | ✓ PASS |
| frontend | 2 | ✓ PASS |
| anki | 4 | ✓ PASS |
| **Total** | **47 resources** | **✓ PASS** |

### Application Resource Validation

```bash
✓ kubectl apply --dry-run=client -f k8s/argocd/applications/argocd.yaml
application.argoproj.io/argocd created (dry run)
```

## Resource Allocation Breakdown

### CPU Limits (Total: 3000m)

**ArgoCD - Critical Components (900m):**
```
application-controller:  500m
repo-server:            200m
server:                 200m
```

**Prometheus (500m):**
```
prometheus:             500m
```

**Applications (1600m):**
```
applications:           350m
influxdb:              250m
postgres:              250m
dns:                   250m
wikijs:                200m
frontend:              150m
anki:                  150m
```

### Capacity Analysis

```
Node Capacity:         4000m (4 cores)
Allocated Limits:      3000m
Headroom:              1000m (25%)
Utilization Target:    75%
```

## Memory Allocation

| Component | Requests | Limits | Current Usage |
|-----------|----------|--------|----------------|
| applications | 1500Mi | 2Gi | 453Mi |
| influxdb | 256Mi | 1500Mi | 781Mi |
| postgres | 256Mi | 512Mi | 67Mi |
| prometheus | 512Mi | 1Gi | 525Mi |
| argocd (all) | ~306Mi | ~1280Mi | 510Mi |
| others | - | - | ~7000Mi |
| **Total** | ~3952Mi | ~8070Mi | 9853Mi (62%) |

**Memory Status:** High utilization at 62% - Priority 2 actions required for optimization

## Validation Commands Used

```bash
# Template rendering
helm template <chart> k8s/charts/<chart>/ | kubectl apply --dry-run=client -f -

# Dry-run validation
kubectl apply --dry-run=client -f k8s/argocd/applications/argocd.yaml

# All charts tested successfully:
for chart in argocd prometheus applications influxdb postgres dns wikijs frontend anki
  helm template $chart k8s/charts/$chart/ | kubectl apply --dry-run=client -f -
done
```

## Ready for Deployment

### Pre-Deployment Checklist

- [x] All YAML manifests validated
- [x] Helm templates render correctly  
- [x] Resource limits within node capacity
- [x] CPU allocation: 3000m (75%)
- [x] Cluster headroom: 1000m (25%)
- [x] No schema errors
- [x] ArgoCD Application resource valid

### Next Steps

1. **Review**: Verify the resource allocation changes
2. **Test**: Deploy to staging (if available)
3. **Deploy**: Apply changes to production via ArgoCD
4. **Monitor**: Watch resource utilization for 24-48 hours
5. **Verify**: Confirm no pod evictions occur

### Deployment Command

```bash
# Apply via ArgoCD (recommended)
kubectl apply -f k8s/argocd/applications/argocd.yaml

# Or manually deploy individual charts
for chart in argocd prometheus applications influxdb postgres dns wikijs frontend anki; do
  helm template $chart k8s/charts/$chart/ | kubectl apply -f -
done
```

## Node Capacity Evaluation

### Current Status

**Hardware:**
- Node: home-server (192.168.178.29)
- CPU: 4 cores (4000m) - Allocatable
- Memory: 16GB - Allocatable  
- Architecture: K3s v1.31.6

**Usage:**
- CPU Usage: 698m (17% - Good)
- Memory Usage: 9853Mi (62% - High)
- Free Headroom: 1.9GB remaining

### Capacity Increase Options

#### Option 1: Physical Hardware Upgrade
**Cost:** €150-700 (CPU + RAM)  
**Time:** 1-2 hours  
**Pros:** Single node, cost-effective  
**Cons:** Downtime required, no HA improvement

#### Option 2: Add Cluster Nodes (RECOMMENDED)
**Cost:** €300-500 per node  
**Time:** 30-60 min per node  
**Pros:** HA, better distribution, no downtime  
**Cons:** Cluster complexity increases

#### Option 3: Cloud Migration
**Cost:** Pay-as-you-go (€20-100/month)  
**Time:** 2-4 weeks migration  
**Pros:** Auto-scaling, managed service  
**Cons:** Less control, vendor lock-in

### Recommendations

**Immediate (Priority 1):**
- ✓ Deploy resource limits (this PR)
- Monitor memory at 80% threshold

**Short-term (1-2 weeks):**
- Add 80% memory alert trigger
- Implement memory cleanup policies
- Review InfluxDB retention (currently 52% of limit)

**Medium-term (2-4 weeks):**
- Add second node for high availability
- Target: 2x 4-core / 16GB minimum
- Reduces single-node failure risk

**Long-term (1-3 months):**
- 3-node setup with split control-plane
- Implement VPA for automatic right-sizing
- Add horizontal pod autoscaling

## References

- **Issue:** #64 - Kubernetes Cluster Resource Optimization
- **Analysis:** KUBERNETES_RESOURCE_ANALYSIS.md
- **Implementation:** PRIORITY_1_IMPLEMENTATION.md
