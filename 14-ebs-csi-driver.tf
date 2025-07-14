data "aws_iam_policy_document" "ebs-csi-driver" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "ebs-csi-driver" {
  name               = "${aws_eks_cluster.eks.name}-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs-csi-driver.json
}

resource "aws_iam_role_policy_attachment" "ebs-csi-driver" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs-csi-driver.name
}

# Optional: only if you want to encrypt the EBS drives
resource "aws_iam_policy" "ebs-csi-driver-encryption" {
  name = "${aws_eks_cluster.eks.name}-ebs-csi-driver-encryption"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:CreateGrant"
        ]
        Resource = "*"
      }
    ]
  })
}

# Optional: only if you want to encrypt the EBS drives
resource "aws_iam_role_policy_attachment" "ebs-csi-driver-encryption" {
  policy_arn = aws_iam_policy.ebs-csi-driver-encryption.arn
  role       = aws_iam_role.ebs-csi-driver.name
}

resource "aws_eks_pod_identity_association" "ebs-csi-driver" {
  cluster_name    = aws_eks_cluster.eks.name
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa"
  role_arn        = aws_iam_role.ebs-csi-driver.arn
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.eks.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.38.1-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs-csi-driver.arn

  depends_on = [aws_eks_node_group.general]
}

# To know latest addon version, run below command
# aws eks describe-addon-versions --region us-east-2 --addon-name aws-ebs-csi-driver
