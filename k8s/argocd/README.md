# Argo CD Installation Summary

## Overview
Argo CD v2.10.3 has been successfully installed on the k3s cluster as part of GitHub issue #43 (Argo CD Migration: Phase 1).

## Installation Details

### 1. Namespace and Installation ✓
- **Namespace**: `argocd` created
- **Version**: 2.10.3 (pinned stable release)
- **Installation Method**: Official Argo CD stable manifest
  ```bash
  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.10.3/manifests/install.yaml
  ```

### 2. Configuration ✓
- **Server Configuration**: Configured with `--insecure` flag via `argocd-cmd-params-cm` ConfigMap
  - This allows Traefik to terminate TLS at the ingress level
  - Key: `server.insecure: "true"`

### 3. Networking ✓
- **IngressRoute**: Added to `k8s/networking/ingressroute.yaml`
  - Host: `argocd.home-lab.com`
  - Service: `argocd-server` (port 80) in the `argocd` namespace
  - Entry point: `web`

- **DNS**: Added A record to `k8s/dns/dns.yaml`
  - Record: `argocd IN A 192.168.178.29`
  - Zone: `home-lab.com`

### 4. Git Repository Connection ✓
- **Authentication Method**: SSH key-based authentication
- **Secret Created**: `git-repository-ssh` in the `argocd` namespace
  - Contains SSH private key from `~/.ssh/ai_vm`
  - Repository URL: `git@github.com:Marvin1912/smart-home-infrastructure.git`

### 5. Initial Access ✓
- **Default Admin Password**: Changed from the initial generated password
  - New password: `newArgoPassword123`
  - Updated in `argocd-secret` with bcrypt hash

## Accessing Argo CD
- **URL**: `https://argocd.home-lab.com` or `http://argocd.home-lab.com` (with Traefik redirecting)
- **Default Username**: `admin`
- **Default Password**: `newArgoPassword123`

**⚠️ Important**: Change this password immediately to a strong, unique password in the Argo CD UI.

## Verification Commands

```bash
# Check all Argo CD pods are running
kubectl get pods -n argocd

# Verify Git repository is connected
kubectl get secret -n argocd git-repository-ssh

# Check IngressRoute is configured correctly
kubectl get ingressroute.traefik.io -o yaml | grep -A 10 argocd

# Verify DNS record
kubectl get configmap -n default coredns-zone -o yaml | grep argocd
```

## Next Steps

1. **Change Admin Password**: Log in to Argo CD UI and change the default password
2. **Configure Applications**: Create Application manifests to deploy workloads
3. **Set Up RBAC**: Configure role-based access control for your team
4. **Enable Notifications**: Set up notifications for application sync events

## Related Files

- Installation manifests: This directory (`k8s/argocd/`)
- Networking config: `k8s/networking/ingressroute.yaml`
- DNS config: `k8s/dns/dns.yaml`
- IngressRoute definition: See networking config above

## References

- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [GitHub Issue #43](https://github.com/Marvin1912/smart-home-infrastructure/issues/43)
- [GitHub Issue #42](https://github.com/Marvin1912/smart-home-infrastructure/issues/42) (Prerequisite)
- [GitHub Issue #41](https://github.com/Marvin1912/smart-home-infrastructure/issues/41) (Parent Epic)
