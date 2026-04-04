# Kubernetes Cluster Resource Analysis
**Date:** 2026-04-04  
**Cluster:** home-server (K3s v1.31.6)

---

## 1. CLUSTER OVERVIEW

### Node Information
| Node | Status | Roles | CPU | Memory | Container Runtime |
|------|--------|-------|-----|--------|-------------------|
| home-server | Ready | control-plane, master | 4 cores | 16 GB | containerd://2.0.2-k3s2 |

---

## 2. CURRENT RESOURCE USAGE

### Node-Level Usage
| Metric | Used | Capacity | Percentage |
|--------|------|----------|-----------|
| **CPU** | 698m | 4000m | **17%** |
| **Memory** | 9853 Mi | ~15.8 GB | **62%** |
| **CPU Requests** | 2400m | 4000m | 60% |
| **CPU Limits** | 4000m | 4000m | 100% |
| **Memory Requests** | 3952 Mi | ~15.8 GB | 24% |
| **Memory Limits** | 8070 Mi | ~15.8 GB | 50% |

### Pod-Level Usage by Namespace

#### **ArgoCD Namespace** (Total: ~126 Mi)
| Pod | CPU | Memory | Status |
|-----|-----|--------|--------|
| argocd-application-controller-0 | 92m | 299 Mi | ⚠️ High (no limits set) |
| argocd-repo-server | 9m | 61 Mi | ✅ Good |
| argocd-server | 4m | 57 Mi | ✅ Good |
| argocd-applicationset-controller | 2m | 29 Mi | ✅ Good |
| argocd-notifications-controller | 2m | 29 Mi | ✅ Good |
| argocd-dex-server | 1m | 24 Mi | ✅ Good |
| argocd-redis | 3m | 10 Mi | ✅ Good |

#### **Default Namespace** (Total: ~2.3 GB)
| Pod | CPU | Memory | Requests | Limits | Status |
|-----|-----|--------|----------|--------|--------|
| influxdb | 34m | **781 Mi** | 250m/256Mi | 500m/1500Mi | ⚠️ High memory usage |
| prometheus | 53m | **525 Mi** | None | None | ⚠️ No limits set |
| applications | 2m | 453 Mi | 750m/1500Mi | 1/2Gi | ✅ Constrained |
| grafana | 7m | 125 Mi | 100m/256Mi | None/1Gi | ✅ Good |
| wikijs | 1m | 150 Mi | 250m/512Mi | 500m/1Gi | ✅ Good |
| alertmanager | 2m | 61 Mi | None/200Mi | None | ⚠️ No CPU limits |
| postgres | 15m | 67 Mi | 250m/256Mi | 500m/512Mi | ✅ Good |
| others | <3m | <40 Mi | — | — | ✅ Good |

#### **Kube-System Namespace** (Total: ~190 Mi)
| Pod | CPU | Memory | Status |
|-----|-----|--------|--------|
| coredns | 5m | 36 Mi | ⚠️ No limits |
| metrics-server | 12m | 29 Mi | ⚠️ No limits |
| traefik | 2m | 57 Mi | ⚠️ No limits |
| sealed-secrets-controller | 1m | 24 Mi | ⚠️ No limits |
| others | <2m | <20 Mi | ✅ Good |

---

## 3. IDENTIFIED ISSUES

### 🔴 **CRITICAL ISSUES**

1. **Missing Resource Limits on ArgoCD Components**
   - `argocd-application-controller`: 92m CPU, 299 Mi RAM with **NO LIMITS**
   - `argocd-repo-server`: 9m CPU, 61 Mi RAM with **NO LIMITS**
   - Risk: OOMKill in multi-tenant scenarios; uncontrolled CPU throttling

2. **Missing Resource Limits on Prometheus**
   - Current: 53m CPU, 525 Mi RAM
   - Risk: Memory spikes during large metric scrapes could evict other pods

3. **InfluxDB High Memory Usage**
   - Current: 34m CPU, 781 Mi RAM (52% of its 1500Mi limit)
   - Risk: Approaching memory limit; could trigger OOMKill under load

### 🟠 **MEDIUM ISSUES**

4. **No Limits on System Pods**
   - coredns, metrics-server, traefik, sealed-secrets: No CPU/memory limits
   - Risk: System components can consume unbounded resources, affecting cluster stability

5. **Overcommitted CPU Limits**
   - CPU Limits Total: 4000m (100% of node capacity)
   - CPU Requests Total: 2400m (60%)
   - Actual Usage: Only 698m (17%)
   - Issue: No headroom if multiple pods spike simultaneously; limits are too high relative to requests

6. **Memory Approaching Capacity**
   - Actual Usage: 9853 Mi (62% of 16GB)
   - Limits Allocated: 8070 Mi (50%)
   - Risk: If actual usage continues trending, limited headroom for new workloads

### 🟡 **MINOR ISSUES**

7. **Inconsistent Resource Definitions**
   - Some pods have both CPU/memory limits; others have only one or neither
   - Makes capacity planning and pod eviction unpredictable

---

## 4. CAPACITY SUMMARY

| Resource | Free | Used | Allocated | Headroom |
|----------|------|------|-----------|----------|
| CPU | 3302m | 698m (17%) | 2400m req | 1402m free |
| Memory | 5945 Mi | 9853 Mi (62%) | 3952m req | 1945 Mi free |

**Conclusion:** Cluster is at **62% memory utilization** with only **1.9 GB headroom**. CPU is underutilized (17%), but limits are overcommitted.

---

## 5. RECOMMENDATIONS

### **PRIORITY 1: Immediate Action Required** (Do This Now)

#### 1.1 Set Resource Limits on ArgoCD Components
```yaml
# argocd-application-controller-0
resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi

# argocd-repo-server
resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 200m
    memory: 256Mi

# argocd-server
resources:
  requests:
    cpu: 25m
    memory: 64Mi
  limits:
    cpu: 200m
    memory: 256Mi
```
**Benefit:** Prevents resource exhaustion; enables pod eviction policies to work correctly.

#### 1.2 Set Limits on Prometheus
```yaml
# prometheus-kube-prometheus-stack-prometheus-0
resources:
  requests:
    cpu: 100m
    memory: 512Mi
  limits:
    cpu: 500m
    memory: 1Gi
```
**Benefit:** Prevents memory spikes from crashing the cluster.

#### 1.3 Reduce CPU Limits (De-overcommit)
Current limits total **4000m** (100%), but requests are only **2400m** (60%).
- **Action:** Reduce CPU limits to ~3000m max (75% of node capacity)
- **Rationale:** Provide 25% headroom for burstable workloads
- **Impact:** Applications with current usage <500m can safely reduce limits by 25-30%

### **PRIORITY 2: Short-term Optimization** (This Week)

#### 2.1 Set Resource Limits on System Pods
```yaml
# coredns
resources:
  requests:
    cpu: 50m
    memory: 32Mi
  limits:
    cpu: 100m
    memory: 128Mi

# metrics-server
resources:
  requests:
    cpu: 50m
    memory: 32Mi
  limits:
    cpu: 100m
    memory: 128Mi

# traefik
resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 200m
    memory: 256Mi
```
**Benefit:** System pod stability; predictable resource consumption.

#### 2.2 Monitor InfluxDB Memory Growth
- Current: 781 Mi / 1500 Mi limit (52%)
- **Action:** Enable monitoring alerts at 80% threshold
- **Watch for:** Time-series data retention policies; consider reducing retention or increasing limits

#### 2.3 Review Memory Requests vs Actual Usage
- Many pods request more than they use (e.g., `applications`: 1500Mi req, 453Mi actual)
- **Action:** Reduce requests to 120% of actual usage for better bin-packing
- **Example:** `applications` → reduce request from 1500Mi to 512Mi

### **PRIORITY 3: Medium-term Planning** (Next Month)

#### 3.1 Add a Second Node for HA
- Current: Single-node cluster with 62% memory utilization
- **Benefit:** Redundancy, better resource distribution, allows pod anti-affinity
- **Recommendation:** Same specs (4 CPU, 16 GB RAM) or larger

#### 3.2 Implement Horizontal Pod Autoscaling (HPA)
- Current: Fixed pod replicas
- **Candidates:** prometheus, influxdb, applications
- **Benefit:** Auto-scale based on CPU/memory usage

#### 3.3 Set Up Cluster Autoscaling
- Once on multi-node, enable K3s autoscaling for cloud deployments
- **Benefit:** Automatic node addition when memory/CPU is exhausted

#### 3.4 Implement Resource Quotas by Namespace
```yaml
# Per-namespace limits to prevent any single namespace from consuming all resources
argocd:
  requests.memory: 1Gi
  limits.memory: 2Gi
  requests.cpu: 500m
  limits.cpu: 1000m

default:
  requests.memory: 8Gi
  limits.memory: 12Gi
  requests.cpu: 2000m
  limits.cpu: 2500m
```

### **PRIORITY 4: Long-term Improvements** (Next Quarter)

#### 4.1 Implement Vertical Pod Autoscaling (VPA)
- Automatically right-size resource requests based on historical usage
- **Benefit:** Optimal resource allocation; reduced waste

#### 4.2 Enable QoS (Quality of Service) Classes
- **Guaranteed:** Critical workloads (prometheus, postgres)
- **Burstable:** Most applications (applications, grafana)
- **BestEffort:** Non-critical (sealed-secrets, traefik)
- **Benefit:** Pod eviction priority during resource pressure

#### 4.3 Implement Node Resource Reservation
```yaml
# Reserve headroom for system/kubelet processes
kubeletReserved:
  cpu: 200m
  memory: 512Mi
systemReserved:
  cpu: 100m
  memory: 256Mi
```

#### 4.4 Upgrade Single-Node Cluster Architecture
- Current: control-plane + all workloads on 1 node
- **Consider:** Separate control-plane from worker nodes (3-node setup)
- **Benefit:** Improved stability, easier maintenance

---

## 6. QUICK WIN: Easy Wins to Implement Today

| Action | Effort | Impact | Priority |
|--------|--------|--------|----------|
| Add CPU/memory limits to ArgoCD | 5 min | 🔴 Critical | 1 |
| Add limits to Prometheus | 5 min | 🔴 Critical | 1 |
| Add limits to system pods | 10 min | 🟠 High | 2 |
| Reduce CPU limits by 20% | 10 min | 🟠 High | 2 |
| Set memory alerts at 80% | 5 min | 🟠 High | 2 |

---

## 7. MONITORING RECOMMENDATIONS

### Add These Prometheus Alerts

```yaml
- alert: KubernetesMemoryUsageHigh
  expr: (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) < 0.2
  for: 5m
  annotations:
    summary: "Node memory < 20% available"

- alert: KubernetesPodMemoryLimitBreach
  expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes) > 0.85
  for: 5m

- alert: KubernetesNoResourceLimits
  expr: |
    kube_pod_container_status_ready{namespace!~"kube-.*"} == 1
    and on(pod, namespace) group_left
    (
      count by (pod, namespace) (kube_pod_container_resource_limits_memory_bytes) == 0
      or count by (pod, namespace) (kube_pod_container_resource_limits_cpu) == 0
    )
```

---

## Summary

✅ **Green**: CPU is well below capacity (17% usage)  
🟠 **Amber**: Memory at 62%, approaching limits in some pods  
🔴 **Red**: Missing resource limits on critical components (ArgoCD, Prometheus, system pods)

**Immediate action needed:** Set resource limits to prevent OOMKill scenarios and enable proper pod eviction policies.
