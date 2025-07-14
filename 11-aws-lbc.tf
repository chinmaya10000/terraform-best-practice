data "aws_iam_policy_document" "aws-lbc" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
        "sts:AssumeRole",
        "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "aws-lbc" {
  name = "${aws_eks_cluster.eks.name}-aws-lbc-role"
  assume_role_policy = data.aws_iam_policy_document.aws-lbc.json
}

resource "aws_iam_policy" "aws-lbc" {
  name = "AWSLoadBalancerController"
  policy = file("./iam/AWSLoadBalancerController.json")
}

resource "aws_iam_role_policy_attachment" "aws-lbc" {
  policy_arn = aws_iam_policy.aws-lbc.arn
  role       = aws_iam_role.aws-lbc.name
}

resource "aws_eks_pod_identity_association" "aws-lbc" {
  cluster_name = aws_eks_cluster.eks.name
  namespace = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn = aws_iam_role.aws-lbc.arn
}

resource "helm_release" "aws-lbc" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart = "aws-load-balancer-controller"
  namespace = "kube-system"
  version = "1.13.0"

  set {
    name = "clusterName"
    value = aws_eks_cluster.eks.name
  }

  set {
    name = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name = "vpcId"
    value = aws_vpc.main.id
  }

  depends_on = [ helm_release.cluster-autoscaler ]
}


# kubectl get pods -n kube-system
# https://github.com/aws/eks-charts/tree/master/stable/aws-load-balancer-controller


# kubectl get ingressclass
# kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
# kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
