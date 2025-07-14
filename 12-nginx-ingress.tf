resource "helm_release" "external-nginx" {
  name = "external-nginx"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart = "ingress-nginx"
  namespace = "ingress"
  create_namespace = true
  version = "4.12.3"

  values = [file("${path.module}/values/nginx-ingress.yaml")]

  depends_on = [ helm_release.aws-lbc ]
}


# kubectl get ingressclass
# # kubectl get svc -n ingress
# # kubectl get pods -o wide -n ingress
