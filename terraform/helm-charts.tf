# ==============================================================================
# HELM CHARTS FOR EKS ADD-ONS
# ==============================================================================

# AWS Load Balancer Controller
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.2"

  set = [
    {
      name  = "clusterName"
      value = data.aws_eks_cluster.main.name
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.aws_load_balancer_controller.arn
    },
    {
      name  = "region"
      value = var.aws_region
    },
    {
      name  = "vpcId"
      value = aws_vpc.main.id
    }
  ]

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.aws_load_balancer_controller
  ]
}

# ==============================================================================
# EBS CSI DRIVER
# ==============================================================================

resource "helm_release" "ebs_csi_driver" {
  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  namespace  = "kube-system"
  version    = "2.28.1"

  set = [
    {
      name  = "controller.serviceAccount.create"
      value = "true"
    },
    {
      name  = "controller.serviceAccount.name"
      value = "ebs-csi-controller-sa"
    },
    {
      name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.ebs_csi.arn
    }
  ]

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.ebs_csi
  ]
}

# ==============================================================================
# CLUSTER AUTOSCALER
# ==============================================================================

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.34.1"

  set = [
    {
      name  = "autoDiscovery.clusterName"
      value = data.aws_eks_cluster.main.name
    },
    {
      name  = "awsRegion"
      value = var.aws_region
    },
    {
      name  = "rbac.serviceAccount.create"
      value = "true"
    },
    {
      name  = "rbac.serviceAccount.name"
      value = "cluster-autoscaler"
    },
    {
      name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.cluster_autoscaler.arn
    },
    {
      name  = "extraArgs.scale-down-delay-after-add"
      value = "10m"
    },
    {
      name  = "extraArgs.scale-down-unneeded-time"
      value = "10m"
    },
    {
      name  = "extraArgs.skip-nodes-with-local-storage"
      value = "false"
    }
  ]

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.cluster_autoscaler
  ]
}

# ==============================================================================
# METRICS SERVER
# ==============================================================================

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.12.0"

  set = [
    {
      name  = "args[0]"
      value = "--cert-dir=/tmp"
    },
    {
      name  = "args[1]"
      value = "--secure-port=4443"
    },
    {
      name  = "args[2]"
      value = "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname"
    },
    {
      name  = "args[3]"
      value = "--kubelet-use-node-status-port"
    },
    {
      name  = "args[4]"
      value = "--metric-resolution=15s"
    }
  ]

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.main
  ]
}