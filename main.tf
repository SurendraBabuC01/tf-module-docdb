resource "aws_docdb_subnet_group" "main" {
  name       = "${var.name}-${var.env}-subg"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, { Name = "${var.name}-${var.env}-subg" })
}

resource "aws_security_group" "main" {
  name        = "${var.name}-${var.env}-sg"
  description = "${var.name}-${var.env}-sg"
  vpc_id      = var.vpc_id

  ingress {
    description = "DB"
    from_port   = var.port_no
    to_port     = var.port_no
    protocol    = "tcp"
    cidr_blocks = var.allow_db_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-${var.env}-sg"
  }
}

resource "aws_docdb_cluster_parameter_group" "main" {
  family      = "docdb4.0"
  name        = "${var.name}-${var.env}-pg"
  description = "${var.name}-${var.env}-pg"
}

resource "aws_docdb_cluster" "docdb" {
  cluster_identifier              = "${var.name}-${var.env}-docdb"
  engine                          = "docdb"
  engine_version                  = var.engine_version
  master_username                 = data.aws_ssm_parameter.db_user.value
  master_password                 = data.aws_ssm_parameter.db_pass.value
  backup_retention_period         = 5
  preferred_backup_window         = "07:00-09:00"
  skip_final_snapshot             = true
  db_subnet_group_name            = aws_docdb_subnet_group.main.name
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.main.name
  port                            = var.port_no
  storage_encrypted               = true
  kms_key_id                      = var.kms_arn
  vpc_security_group_ids          = [aws_security_group.main.id]

  tags = merge(var.tags, { Name = "${var.name}-${var.env}-docdb" })
}

resource "aws_docdb_cluster_instance" "cluster_instances" {
  count              = var.instance_count
  identifier         = "${var.name}-${var.env}-docdb-${count.index}"
  cluster_identifier = aws_docdb_cluster.docdb.id
  instance_class     = var.instance_class
}

