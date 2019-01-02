resource "aws_iam_role" "kubernetes_worker_role" {
  name = "kubernetes-worker-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
    "Action": "sts:AssumeRole",
    "Effect": "Allow",
    "Sid": "",
    "Principal": {
    "Service": "ec2.amazonaws.com"
    }
  }
  ]
}
EOF
}


resource "aws_iam_role" "kubernetes_pod_role" {
  name = "kubernetes-pod-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
    "Action": "sts:AssumeRole",
    "Effect": "Allow",
    "Sid": "",
    "Principal": {
    "Service": "ec2.amazonaws.com"
    }
  }
  ]
}
EOF
}
