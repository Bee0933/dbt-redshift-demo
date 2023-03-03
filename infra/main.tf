# resources

# vpc
resource "aws_vpc" "dbt-vpc" {
  cidr_block           = var.vpc-cidr-block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.env-prefix}_ny_taxi_vpc"
  }
}

# subnets
resource "aws_subnet" "dbt-public-subnet-1" {
  vpc_id            = aws_vpc.dbt-vpc.id
  cidr_block        = var.public-subnet-cidr-block
  availability_zone = "${var.avail-zone}b"

  tags = {
    Name = "${var.env-prefix}_public_subnet_1"
  }
}

# subnet group
resource "aws_redshift_subnet_group" "redshift-subnet-group" {

  name = "redshift-subnet-group"

  subnet_ids = [aws_subnet.dbt-public-subnet-1.id]

  tags = {

    environment = "${var.env-prefix}"
    Name        = "${var.env-prefix}-redshift-subnet-group"
  }

}

# route tables
resource "aws_route_table" "dbt-route-table" {
  vpc_id = aws_vpc.dbt-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dbt-igw.id
  }

  tags = {
    Name = "${var.env-prefix}_dbt_route_table"
  }
}

# Gateway
resource "aws_internet_gateway" "dbt-igw" {
  vpc_id = aws_vpc.dbt-vpc.id

  tags = {
    Name = "${var.env-prefix}_dbt_gateway"
  }
}

# Associations
resource "aws_route_table_association" "dbt-a-rtb-subnet" {
  subnet_id      = aws_subnet.dbt-public-subnet-1.id
  route_table_id = aws_route_table.dbt-route-table.id
}


# security 
resource "aws_security_group" "dbt-sg" {
  name        = "dbt-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.dbt-vpc.id

  depends_on = [aws_vpc.dbt-vpc]

  ingress {
    description = "Redshift TLS from VPC"
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["${var.my-ip}"]
  }

  # ingress {
  #   description = "TLS from VPC"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env-prefix}_ny_taxi_sg"
  }
}


# s3
resource "aws_s3_bucket" "dbt-s3" {
  bucket = "dbt-s3"

  tags = {
    Name        = "dbt-s3"
    Environment = "${var.env-prefix}_environment"
  }
}

resource "aws_s3_bucket_acl" "ny-taxi-lake-acl" {
  bucket = aws_s3_bucket.dbt-s3.id
  acl    = "private"
}


# redshift
# IAM Role

# Create an IAM Role for Redshift
resource "aws_iam_role" "redshift-serverless-role" {
  name = "dbt-redshift-serverless-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "redshift.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name        = "dbt-redshift-serverless-role"
    Environment = var.env-prefix
  }
}

# Create and assign an IAM Role Policy to access S3 Buckets
resource "aws_iam_role_policy" "redshift-s3-full-access-policy" {
  name = "dbt-redshift-serverless-role-s3-policy"
  role = aws_iam_role.redshift-serverless-role.id

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
     {
       "Effect": "Allow",
       "Action": "s3:*",
       "Resource": "*"
      }
   ]
}
EOF
}


# cluster 
resource "aws_redshift_cluster" "dbt-cluster" {
  cluster_identifier        = "dbt-cluster"
  database_name             = var.rs-database-name
  master_username           = var.rs-master-username
  master_password           = var.rs-master-pass
  node_type                 = "dc2.large"
  cluster_type              = "single-node"
  cluster_subnet_group_name = aws_redshift_subnet_group.redshift-subnet-group.id
  skip_final_snapshot       = true
  iam_roles                 = ["${aws_iam_role.redshift-serverless-role.arn}"]
  depends_on                = [aws_vpc.dbt-vpc, aws_security_group.dbt-sg, aws_redshift_subnet_group.redshift-subnet-group, aws_iam_role.redshift-serverless-role]

}
