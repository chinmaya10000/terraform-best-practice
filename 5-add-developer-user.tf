resource "aws_iam_user" "developer" {
  name = "developer"
}

resource "aws_iam_policy" "developer_eks" {
  name        = "AmazonEKSDeveloperPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
            "eks:DescribeCluster",
            "eks:ListClusters"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_user_policy_attachment" "developer_eks" {
  user       = aws_iam_user.developer.name
  policy_arn = aws_iam_policy.developer_eks.arn
}


resource "aws_eks_access_entry" "example" {
  cluster_name      = aws_eks_cluster.eks.name
  principal_arn     = aws_iam_role.developer.arn
  kubernetes_groups = ["my-viewer"]
}
