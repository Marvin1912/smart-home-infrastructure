# k8s/jobs

One-off Kubernetes Jobs for manual maintenance operations. These are **not** managed by ArgoCD — apply them directly with `kubectl apply -f` when needed.

---

## wikijs-db-flush.yaml

Truncates all Wiki.js tables in the shared `costs` PostgreSQL database to allow a clean re-sync from the GitHub-backed Git storage. Only Wiki.js-specific tables are targeted; data from other apps sharing the database (`stock-portfolio-tracker`, `bp-tracker`) is left untouched.

**When to use:** Orphaned pages remain after restructuring the wiki in Git. A full table flush forces Wiki.js to rebuild its schema and re-import all pages from Git on next startup.

### Usage

```bash
# 1. Scale down Wiki.js to prevent writes during truncation
kubectl scale deployment wikijs --replicas=0 -n default

# 2. Run the flush job
kubectl apply -f k8s/jobs/wikijs-db-flush.yaml

# 3. Watch progress
kubectl logs -f -l job-name=wikijs-db-flush -n default

# 4. Sync the wikijs ArgoCD application — restores replicas and triggers Git re-sync
```

The job auto-deletes 5 minutes after completion (`ttlSecondsAfterFinished: 300`).
