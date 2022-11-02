# Creates a role for the Loki pods to access the pre-created S3 bucket
# for Loki backend.
#
# Assumption, the bucket var.s3_bucket is already created in same region 
#
# Note: if you changed module name in eks.tf from "opsverse-eks-cluster", please
#       update this script to replace "opsverse-eks-cluster".

resource "aws_iam_role" "iam_for_loki_pods" {
  name = "eks-opsverse-s3-pod-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${module.opsverse-eks-cluster.oidc_provider_arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition":  {
        "StringLike": {
          "${replace(module.opsverse-eks-cluster.oidc_provider_arn, "${element(split("/", module.opsverse-eks-cluster.oidc_provider_arn), 0)}/", "")}:sub": "system:serviceaccount:*:${var.s3_bucket}"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_policy" "loki_pod_permissions" {
  name   = "opsverse-eks-pod-permissions"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${var.s3_bucket}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${var.s3_bucket}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "tag:GetResources",
                "cloudwatch:GetMetricData",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:ListMetrics"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF 
}

resource "aws_iam_role_policy_attachment" "loki_pod_permissions" {
  role       = aws_iam_role.iam_for_loki_pods.name
  policy_arn = aws_iam_policy.loki_pod_permissions.arn
}

output "loki_pod_role_arn" {
  value = aws_iam_role.iam_for_loki_pods.arn 
}
