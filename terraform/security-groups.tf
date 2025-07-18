# ==============================================================================
# EKS CLUSTER SECURITY GROUP
# ==============================================================================

resource "aws_security_group" "cluster" {
  name_prefix = "${var.cluster_name}-cluster-sg"
  vpc_id      = aws_vpc.main.id
  description = "Security group for EKS cluster control plane"

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.cluster_name}-cluster-sg"
    Type = "EKS-Cluster"
  }
}

# ==============================================================================
# EKS NODE GROUP SECURITY GROUP
# ==============================================================================

resource "aws_security_group" "node_group" {
  name_prefix = "${var.cluster_name}-node-sg"
  vpc_id      = aws_vpc.main.id
  description = "Security group for EKS worker nodes"

  # Allow nodes to communicate with each other (all TCP ports)
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
    description = "Allow nodes to communicate with each other"
  }

  # Allow nodes to communicate with each other (UDP)
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    self        = true
    description = "Allow UDP communication between nodes"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.cluster_name}-node-sg"
    Type = "EKS-Nodes"
  }
}

# ==============================================================================
# SECURITY GROUP RULES (Created after both SGs exist)
# ==============================================================================

# Allow HTTPS from nodes to cluster
resource "aws_security_group_rule" "cluster_ingress_nodes_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node_group.id
  security_group_id        = aws_security_group.cluster.id
  description              = "Allow HTTPS from worker nodes"
}

# Allow kubelet API from cluster to nodes
resource "aws_security_group_rule" "node_ingress_cluster_kubelet" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.node_group.id
  description              = "Allow kubelet API from cluster"
}

# Allow cluster to communicate with nodes (extended port range)
resource "aws_security_group_rule" "node_ingress_cluster_all" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.node_group.id
  description              = "Allow cluster to communicate with nodes"
}

# ==============================================================================
# APPLICATION LOAD BALANCER SECURITY GROUP
# ==============================================================================

resource "aws_security_group" "alb" {
  name_prefix = "${var.cluster_name}-alb-sg"
  vpc_id      = aws_vpc.main.id
  description = "Security group for Application Load Balancer"

  # Allow HTTP from internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from internet"
  }

  # Allow HTTPS from internet
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from internet"
  }

  # Allow outbound HTTPS
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS outbound"
  }

  tags = {
    Name = "${var.cluster_name}-alb-sg"
    Type = "ALB"
  }
}

# ALB to nodes rule (separate to avoid cycles)
resource "aws_security_group_rule" "alb_egress_nodes" {
  type                     = "egress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node_group.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow traffic to NodePort services"
}