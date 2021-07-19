resource "aws_eks_cluster" "cluster" {
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]
  name       = var.cluster-name
  
  role_arn   = aws_iam_role.eks-cluster-ServiceRole-HUIGIC7K7HNJ.arn
  tags       = {}
  version    = "1.18"

  timeouts {}

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true
    public_access_cidrs = [
      "0.0.0.0/0",
    ]
    security_group_ids = [
      aws_security_group.allnodes-sg.id
    ]
    subnet_ids = module.vpc.private_subnets

  }
}

data "aws_ssm_parameter" "eksami" {
  name=format("/aws/service/eks/optimized-ami/%s/amazon-linux-2/recommended/image_id", aws_eks_cluster.cluster.version)
}

locals {
  eks-node-private-userdata = <<USERDATA
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="
--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash -xe
sudo /etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.cluster.certificate_authority[0].data}' '${aws_eks_cluster.cluster.name}'
echo "Running custom user data script" > /tmp/me.txt
yum install -y amazon-ssm-agent
echo "yum'd agent" >> /tmp/me.txt
systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent
date >> /tmp/me.txt
--==MYBOUNDARY==--
USERDATA
}


resource "aws_launch_template" "lt-ng1" {
  instance_type           = "t3.small"
  key_name                = "eksworkshop"
  name                    = format("at-lt-%s-ng1", aws_eks_cluster.cluster.name)
  tags                    = {}
  image_id                = "ami-09d01d46812c52d7d"
  user_data            = base64encode(local.eks-node-private-userdata)
  vpc_security_group_ids  = [aws_security_group.allnodes-sg.id] 
  tag_specifications { 
        resource_type = "instance"
    tags = {
        Name = format("%s-ng1", aws_eks_cluster.cluster.name)
        }
    }
  lifecycle {
    create_before_destroy=true
  }
}

resource "aws_eks_node_group" "ng1" {
  #ami_type       = "AL2_x86_64"
  depends_on     = [aws_launch_template.lt-ng1]
  cluster_name   = aws_eks_cluster.cluster.name
  disk_size      = 0
  instance_types = []
  labels = {
    "eks/cluster-name"   = aws_eks_cluster.cluster.name
    "eks/nodegroup-name" = format("ng1-%s", aws_eks_cluster.cluster.name)
  }
  node_group_name = format("ng1-%s", aws_eks_cluster.cluster.name)
  node_role_arn   = aws_iam_role.eks-nodegroup-ng-ma-NodeInstanceRole-1GFKA1037E1XO.arn
 
  subnet_ids = module.vpc.private_subnets
  tags = {
    "eks/cluster-name"                = aws_eks_cluster.cluster.name
    "eks/eksctl-version"              = "0.29.2"
    "eks/nodegroup-name"              = format("ng1-%s", aws_eks_cluster.cluster.name)
    "eks/nodegroup-type"              = "managed"
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name" = aws_eks_cluster.cluster.name
    format("k8s.io/cluster-autoscaler/%s",aws_eks_cluster.cluster.name) = "owned"
    "k8s.io/cluster-autoscaler/enabled" = "TRUE"
  }
  #version = "1.17"

  launch_template {
    name    = aws_launch_template.lt-ng1.name
    version = "1"
  }

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  # lifecycle {
  #   ignore_changes = [scaling_config[0].desired_size]
  # }

  timeouts {}
}


## OIDC Provider
data "tls_certificate" "cluster" {
  url = aws_eks_cluster.cluster.identity.0.oidc.0.issuer
}
resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list = ["sts.amazonaws.com"]
#  thumbprint_list = concat([data.tls_certificate.cluster.certificates.0.sha1_fingerprint], var.oidc_thumbprint_list)
  thumbprint_list = [data.tls_certificate.cluster.certificates.0.sha1_fingerprint]
  url = aws_eks_cluster.cluster.identity.0.oidc.0.issuer
}


### Enabling IAM Roles for Service Accounts  for aws-node pod
data "aws_iam_policy_document" "cluster_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.cluster.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "cluster" {
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role_policy.json
  name               = format("irsa-%s-aws-node", aws_eks_cluster.cluster.name)
}

output oidc_provider_arn {
  value=aws_iam_openid_connect_provider.cluster.arn
}


output cluster-name {
  value=aws_eks_cluster.cluster.name
}


output ca {
  value=aws_eks_cluster.cluster.certificate_authority[0].data
}

output endpoint {
  value=aws_eks_cluster.cluster.endpoint
}