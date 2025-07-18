# ==============================================================================
# VPC - Virtual Private Cloud (our isolated network in AWS)
# ==============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true # Required for EKS
  enable_dns_support   = true # Required for EKS

  tags = {
    Name                                        = "${var.cluster_name}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared" # Required for EKS
  }
}

# ==============================================================================
# INTERNET GATEWAY - Allows internet access for public subnets
# ==============================================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

# ==============================================================================
# PUBLIC SUBNETS - For load balancers and NAT gateways
# ==============================================================================

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true # Instances get public IPs

  tags = {
    Name                                        = "${var.cluster_name}-public-${var.availability_zones[count.index]}"
    Type                                        = "Public"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1" # For load balancers
  }
}

# ==============================================================================
# PRIVATE SUBNETS - For worker nodes (more secure)
# ==============================================================================

resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                                        = "${var.cluster_name}-private-${var.availability_zones[count.index]}"
    Type                                        = "Private"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned" # EKS owns these subnets
    "kubernetes.io/role/internal-elb"           = "1"     # For internal load balancers
  }
}

# ==============================================================================
# ELASTIC IPs - Static IP addresses for NAT gateways
# ==============================================================================

resource "aws_eip" "nat" {
  count = length(var.availability_zones)

  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.cluster_name}-nat-eip-${var.availability_zones[count.index]}"
  }
}

# ==============================================================================
# NAT GATEWAYS - Allow private subnets to access internet (outbound only)
# ==============================================================================

resource "aws_nat_gateway" "main" {
  count = length(var.availability_zones)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.main]

  tags = {
    Name = "${var.cluster_name}-nat-${var.availability_zones[count.index]}"
  }
}

# ==============================================================================
# ROUTE TABLES - Define how traffic flows in our network
# ==============================================================================

# Public route table - routes traffic to internet gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0" # All traffic
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

# Private route tables - one per AZ, routes traffic to NAT gateway
resource "aws_route_table" "private" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0" # All traffic
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.cluster_name}-private-rt-${var.availability_zones[count.index]}"
  }
}

# ==============================================================================
# ROUTE TABLE ASSOCIATIONS - Connect subnets to route tables
# ==============================================================================

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associate private subnets with their respective private route tables
resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}