# Kubernetes Dependencies Setup

This guide provides step-by-step instructions to install and configure the required dependencies: **cert-manager**, **KGateway**, and **CloudNativePG (CNPG)**, and to patch necessary resources for Helm compatibility.

---

## 1. Install cert-manager

Apply the cert-manager manifests:

```sh
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.2/cert-manager.yaml
```

### Patch cert-manager Deployment

Enable the Gateway API by patching the first container’s arguments:

```sh
kubectl patch deployment cert-manager -n cert-manager \
  --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--enable-gateway-api"}]'
```

### Restart cert-manager

```sh
kubectl rollout restart deployment cert-manager -n cert-manager
```

---

## 2. Install KGateway

First, apply the **Gateway API CRDs**:

```sh
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
```

Then, install **KGateway CRDs** and **KGateway** using Helm:

```sh
helm upgrade -i --create-namespace --namespace kgateway-system \
  --version v2.0.4 kgateway-crds \
  oci://cr.kgateway.dev/kgateway-dev/charts/kgateway-crds
```

```sh
helm upgrade -i --namespace kgateway-system \
  --version v2.0.4 kgateway \
  oci://cr.kgateway.dev/kgateway-dev/charts/kgateway
```

---

## 3. Install CloudNativePG (CNPG)

Apply CNPG operator manifests:

```sh
kubectl apply --server-side -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.25/releases/cnpg-1.25.3.yaml
```

---

## 4. Patch ClusterIssuer for Helm Ownership

If you already have a `ClusterIssuer` (e.g., `letsencrypt-prod`), you need to patch it to be managed by Helm:

```sh
kubectl patch clusterissuer letsencrypt-prod \
  --type merge \
  -p '{
    "metadata": {
      "labels": {
        "app.kubernetes.io/managed-by": "Helm"
      },
      "annotations": {
        "meta.helm.sh/release-name": "bashshie",
        "meta.helm.sh/release-namespace": "helm"
      }
    }
  }'
```

---

## Summary

This setup ensures:

- **cert-manager** is installed with Gateway API enabled  
- **KGateway** (CRDs + controller) is deployed in `kgateway-system` namespace  
- **CloudNativePG** operator is installed  
- `ClusterIssuer` is patched to align with Helm release metadata  

---
