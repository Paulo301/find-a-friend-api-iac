resource "aws_iam_openid_connect_provider" "oidc-git" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  tags = {
    IAC = true
  }
}

resource "aws_iam_role" "ecr-role" {
  name = "ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect : "Allow",
        Action : "sts:AssumeRoleWithWebIdentity",
        Principal : {
          Federated : ""
        },
        Condition : {
          StringEquals : {
            "token:aud" : [""],
            "token:sub" : [""]
          }
        }
      },
    ]
  })

  tags = {
    IAC = true
  }
}

resource "aws_iam_role_policy" "ecr-role-policy" {
  name = "ecr-role-policy"
  role = aws_iam_role.ecr-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "Statement1",
        Action   = "apprunnner:*",
        Effect   = "Allow",
        Resource = "*",
      },
      {
        Sid      = "Statement2",
        Action   = ["iam:PassRole", "iam:CreateServiceLinkedRole"],
        Effect   = "Allow",
        Resource = "*",
      },
      {
        Sid = "Statement3"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:GetAuthorizationToken",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  depends_on = [aws_iam_role.ecr-role]
}

resource "aws_iam_role" "tf-role" {
  name = "tf-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect : "Allow",
        Action : "sts:AssumeRoleWithWebIdentity",
        Principal : {
          Federated : "arc"
        },
        Condition : {
          StringEquals : {
            "token:aud" = [""],
            "token:sub" = [""]
          }
        }
      },
    ]
  })

  tags = {
    IAC = true
  }
}

data "aws_iam_policy_document" "tf-policy" {
  statement {
    effect    = "Allow"
    actions   = ["ecr:*"]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["iam:*"]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "tf-policy" {
  name   = "tf-policy"
  policy = data.aws_iam_policy_document.tf-policy.json
}


resource "aws_iam_role_policy_attachment" "tf-policy-attachment" {
  role       = aws_iam_role.tf-role
  policy_arn = aws_iam_policy.tf-policy.arn

  depends_on = [aws_iam_role.tf-role]
}

resource "aws_iam_role" "app-runner-role" {
  name = "app-runner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect : "Allow",
        Action : "sts:AssumeRole",
        Principal : {
          Service : "build.apprunner.amazonaws.com"
        },
      },
    ]
  })

  tags = {
    IAC = true
  }
}

data "aws_iam_policy_document" "app-runner-policy" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:ReadOnly"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "app-runner-policy" {
  name   = "app-runner-policy"
  policy = data.aws_iam_policy_document.app-runner-policy.json
}


resource "aws_iam_role_policy_attachment" "app-runner-policy-attachment" {
  role       = aws_iam_role.app-runner-role
  policy_arn = aws_iam_policy.app-runner-policy.arn

  depends_on = [aws_iam_role.app-runner-role]
}
