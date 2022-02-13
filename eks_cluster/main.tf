
module "iam_roles" {
  source = "./iam_roles"

  prefix = var.prefix
}

resource "aws_eks_cluster" "cluster" {
  name     = format("%s_cluster", var.prefix)
  role_arn = module.iam_roles.cluster.arn

  vpc_config {
    subnet_ids = var.subnet_ids
  }

  tags = {
    "Name" = format("%s_cluster", var.prefix)
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    module.iam_roles
  ]
}

resource "aws_eks_node_group" "eks_example" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = format("%s_node_group", var.prefix)
  node_role_arn   = module.iam_roles.node_group.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = 5
    max_size     = 7
    min_size     = 3
  }

  update_config {
    max_unavailable = 2
  }

  tags = {
    "Name" : format("%s_node_group", var.prefix)
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    module.iam_roles
  ]
}
