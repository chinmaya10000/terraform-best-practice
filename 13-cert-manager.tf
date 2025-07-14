resource "helm_release" "cert-manager" {
  name = "cert-manager"

  repository = "https://charts.jetstack.io"
  chart = "cert-manager"
  version = "1.18.0"
  namespace = "cert-manager"
  create_namespace = true

  set {
    name = "installCRDs"
    value = "true"
  }

  depends_on = [ helm_release.external-nginx ]
}


# # kubectl get pods -n cert-manager