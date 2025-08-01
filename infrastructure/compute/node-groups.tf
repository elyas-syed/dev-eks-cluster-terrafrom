# ==============================================================================
# EKS MANAGED NODE GROUPS
# ==============================================================================

resource "aws_eks_node_group" "main" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-${each.key}"
  node_role_arn   = var.node_group_role_arn
  subnet_ids      = var.private_subnet_ids

  # Instance configuration
  instance_types = each.value.instance_types
  capacity_type  = lookup(each.value, "capacity_type", "ON_DEMAND")
  ami_type       = lookup(each.value, "ami_type", "AL2_x86_64")

  # Scaling configuration
  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  # Update configuration
  update_config {
    max_unavailable_percentage = 25 # Allow 25% of nodes to be unavailable during updates
  }

  # Launch template configuration
  launch_template {
    name    = aws_launch_template.node_group[each.key].name
    version = aws_launch_template.node_group[each.key].latest_version
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${each.key}-node-group"
  })
}

# ==============================================================================
# LAUNCH TEMPLATES FOR NODE GROUPS
# ==============================================================================

resource "aws_launch_template" "node_group" {
  for_each = var.node_groups

  name_prefix = "${var.cluster_name}-${each.key}-"

  # EBS configuration
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = lookup(each.value, "disk_size", 20)
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  # Security configuration
  vpc_security_group_ids = [var.node_group_security_group_id]

  # Metadata options (IMDSv2)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.cluster_name}-${each.key}-node"
    })
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${each.key}-launch-template"
  })
}