# Linkwarden Kubernetes Deployment Notes

## Resource Overview
- `namespace.yaml`: Creates the `linkwarden` namespace; update the metadata name and any labels/annotations before applying if a different namespace is required.
- `secret.yaml`: Stores PostgreSQL credentials and Linkwarden secret values. Adjust the secret name or key names, and update the deployment/service references if you rename it.
- `postgres-pvc.yaml` & `linkwarden-postgres` deployment/service: Keep the PVC name in sync with the Postgres Deployment volume definition if renaming storage resources.
- `app-pvc.yaml` & `deployment.yaml`: These control where Linkwarden stores attachments/backups. Change the PVC name in both manifests if a different storage resource is desired.
- `service.yaml` & `ingress.yaml`: Service and Ingress reference the `linkwarden` Service name and TLS secret (`linkwarden-tls`). Update these references if you rename the service or TLS secret.

## Customizing Names & Secrets
1. **Namespace**: Apply the namespace manifest first or update other manifests to refer to your existing namespace. If you reuse another namespace, remove or adjust `namespace:` fields accordingly.
2. **Secrets**: When renaming `linkwarden-secrets`, update all `valueFrom.secretKeyRef.name` blocks across `postgres-deployment.yaml`, `deployment.yaml`, and any other manifest referencing the secret.
3. **PVCs**: `linkwarden-postgres-pvc` and `linkwarden-app-pvc` are referenced directly in the Postgres and application deployments. Keep their names consistent or update both the PVC and consuming pods.
4. **Ingress & Service**: The Ingress rule targets `linkwarden.example.com` and expects a `linkwarden` Service on port 3000. Adjust the host, service name, port, or TLS secret (`linkwarden-tls`) if bringing your own certificates or domain.

## Applying Manifests
Use the namespace manifest first, e.g.: `kubectl apply -f k8s/linkwarden/namespace.yaml`.
Apply the rest with `kubectl apply -f k8s/linkwarden/` once secrets, storage, and TLS secrets exist in the target namespace.
