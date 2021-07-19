resource "aws_iam_role" "eks-cluster-ServiceRole-HUIGIC7K7HNJ" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = [
              "eks-fargate-pods.amazonaws.com",
              "eks.amazonaws.com",
            ]
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  force_detach_policies = false
  max_session_duration  = 3600
  name                  = "eks-cluster-ServiceRole-HUIGIC7K7HNJ"
  path                  = "/"
  tags = {
    "Name"                                        = "eks-cluster/ServiceRole"

  }
}

resource "aws_iam_policy_attachment" "eks-cluster-aws-managed-policy-attachment" {
  name       = "test-attachment"
  roles      = [aws_iam_role.eks-cluster-ServiceRole-HUIGIC7K7HNJ.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

output "cluster_service_role_arn" {
  value = aws_iam_role.eks-cluster-ServiceRole-HUIGIC7K7HNJ.arn
}
