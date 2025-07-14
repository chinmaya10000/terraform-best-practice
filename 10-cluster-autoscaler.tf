resource "aws_iam_role" "cluster-autoscaler" {
  name = "eks-cluster-autoscaler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Principal = {
                Service = "pods.eks.amazonaws.com"
            }
            Action = [
                "sts:AssumeRole",
                "sts:TagSession"
            ]
        }
    ]
  })
}

resource "aws_iam_policy" "cluster-autoscaler" {
  name = "eks-cluster-autoscaler-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Action = [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeScalingActivities",
                "autoscaling:DescribeTags",
                "ec2:DescribeImages",
                "ec2:DescribeInstanceTypes",
                "ec2:DescribeLaunchTemplateVersions",
                "ec2:GetInstanceTypesFromInstanceRequirements",
                "eks:DescribeNodegroup"
            ]
            Resource = "*"
        },
        {
            Effect = "Allow"
            Action = [
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup"
            ]
            Resource = "*"
        },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster-autoscaler" {
  role = aws_iam_role.cluster-autoscaler.name
  policy_arn = aws_iam_policy.cluster-autoscaler.arn
}

resource "aws_eks_pod_identity_association" "cluster-autoscaler" {
  cluster_name = aws_eks_cluster.eks.name
  namespace = "kube-system"
  service_account = "cluster-autoscaler"
  role_arn = aws_iam_role.cluster-autoscaler.arn
}

resource "helm_release" "cluster-autoscaler" {
  name = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart = "cluster-autoscaler"
  namespace = "kube-system"
  version = "9.47.0"

  set {
    name = "autoDiscovery.clusterName"
    value = aws_eks_cluster.eks.name
  }

  set {
    name = "awsRegion"
    value = local.aws_region
  }

  set {
    name = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }

  depends_on = [ helm_release.metrics_server ]
}


# kubectl get pod -n kube-system
# kubectl logs -l app.kubernetes.io/instance=autoscaler -f -n kube-system
