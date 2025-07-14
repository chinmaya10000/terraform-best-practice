resource "helm_release" "metrics_server" {
  name = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart = "metrics-server"
  namespace = "kube-system"
  version = "3.12.2"

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }

  set {
    name  = "args[1]"
    value = "--kubelet-preferred-address-types=InternalIP"
  }

  depends_on = [ aws_eks_node_group.general ]
}



# Kubectl get pods -n kube-system
# kubectl logs -l app.kubernetes.io/instance=metrics-server -f -n kube-system
# kubectl top nodes