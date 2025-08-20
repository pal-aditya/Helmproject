
# Install kgateway CRD's
resource "helm_release" "kgateway_crds" {
  name       = "kgateway-crds"
  repository = "oci://cr.kgateway.dev/kgateway-dev/charts"
  chart      = "kgateway-crds"
  version    = "2.0.4"
  namespace  = kubernetes_namespace.kgateway.metadata[0].name
}

# Install kgateway
resource "helm_release" "kgateway" {
  name       = "kgateway"
  repository = "oci://cr.kgateway.dev/kgateway-dev/charts"
  chart      = "kgateway"
  version    = "2.0.4"
  namespace  = kubernetes_namespace.kgateway.metadata[0].name
  depends_on = [helm_release.kgateway_crds]
}

# CNPG (CloudNative PG)
data "external" "cnpostgress" {
  program = ["bash", "-c", <<EOT
    content=$(curl -s -L https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.25/releases/cnpg-1.25.3.yaml)
    jq -n --arg content "$content" '{content:$content}'
  EOT
  ]
}

resource "kubernetes_manifest" "cnpg" {
  manifest = yamldecode(data.external.cnpostgress.result["content"])
}

# Cert-manager
data "external" "cert" {
  program = ["bash", "-c", <<EOT
    content=$(curl -s -L https://github.com/cert-manager/cert-manager/releases/download/v1.18.2/cert-manager.yaml)
    jq -n --arg content "$content" '{content:$content}'
  EOT
  ]
}

resource "kubernetes_manifest" "certmanager" {
  manifest = yamldecode(data.external.cert.result["content"])
}
