
resource "aws_security_group" "allnodes-sg" {
  description = "Communication between the control plane and worker nodegroups"
  vpc_id      = module.vpc.vpc_id
  tags = {
    "Name" = "EKS cluster SG"
  }
}





resource "aws_security_group_rule" "eks-node-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.allnodes-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "eks-all-node" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  source_security_group_id = aws_security_group.allnodes-sg.id
  security_group_id = aws_security_group.cluster-sg.id
}

resource "aws_security_group_rule" "eks-node-all" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  source_security_group_id = aws_security_group.cluster-sg.id
  security_group_id = aws_security_group.allnodes-sg.id
}


resource "aws_security_group_rule" "eks-node-self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self = true
  security_group_id = aws_security_group.allnodes-sg.id
}




output "allnodes-sg" {
  value = aws_security_group.allnodes-sg.id
}