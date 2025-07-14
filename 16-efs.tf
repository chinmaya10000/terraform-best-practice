# It's fully elastic file storage - scales automatically when you add or remove files.
# You can use the ReadWriteMany access mode - you can mount the same volume to multiple pods.
# More expensive than EBS - Standard (GB-Month) $0.30 (us-east-2)

# Create the EFS file system
resource "aws_efs_file_system" "eks" {
  creation_token = "eks"

  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  encrypted = "true"

#   lifecycle_policy {
#     transition_to_ia = "AFTER_30_DAYS"
#   }
}

# Mount target in each private subnet
resource "aws_efs_mount_target" "private" {
  for_each        = aws_subnet.private
  file_system_id  = aws_efs_file_system.eks.id
  subnet_id       = each.value.id
  security_groups = [aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id]
}

# IAM policy document for EFS CSI driver service account
data "aws_iam_policy_document" "efs_csi_driver" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:efs-csi-controller-sa"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

# IAM role for EFS CSI driver
resource "aws_iam_role" "efs_csi_driver" {
  name               = "${aws_eks_cluster.eks.name}-efs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.efs_csi_driver.json
}

# Attach AWS-managed EFS CSI policy to the IAM role
resource "aws_iam_role_policy_attachment" "efs_csi_driver" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  role       = aws_iam_role.efs_csi_driver.name
}

# Deploy the EFS CSI driver using Helm
resource "helm_release" "efs_csi_driver" {
  name = "aws-efs-csi-driver"

  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  chart = "aws-efs-csi-driver"
  namespace = "kube-system"
  version = "3.1.5"

  set {
    name = "controller.serviceAccount.name"
    value = "efs-csi-controller-sa"
  }

  set {
    name = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.efs_csi_driver.arn
  }

  depends_on = [aws_efs_mount_target.private]
}

# Optional since we already init helm provider (just to make it self contained)
data "aws_eks_cluster" "eks_v2" {
  name = aws_eks_cluster.eks.name
}

# Optional since we already init helm provider (just to make it self contained)
data "aws_eks_cluster_auth" "eks_v2" {
  name = aws_eks_cluster.eks.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks_v2.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_v2.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks_v2.token
}

# Define EFS storage class
resource "kubernetes_storage_class_v1" "efs" {
  metadata {
    name = "efs"
  }

  storage_provisioner = "efs.csi.aws.com"

  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId = aws_efs_file_system.eks.id
    directoryPerms = "700"
  }

  mount_options = ["iam"]

  reclaim_policy = "Retain"

  depends_on = [helm_release.efs_csi_driver]
}


# kubectl get pod -n kube-system
# kubectl logs -l app.kubernetes.io/instance=aws-efs-csi-driver -n kube-system