resource "aws_iam_group" "this" {
  name = var.group_name
}

resource "aws_iam_policy" "this" {
  name        = var.policy_name
  description = "Least privilege access for Terraform"
  policy      = file("${path.module}/policy.json")
}

resource "aws_iam_group_policy_attachment" "this" {
  group      = aws_iam_group.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "aws_iam_user" "this" {
  name = var.user_name
  tags = {
    Role = "Terraform"
  }
}

resource "aws_iam_user_group_membership" "this" {
  user   = aws_iam_user.this.name
  groups = [aws_iam_group.this.name]
}

resource "aws_iam_access_key" "this" {
  user = aws_iam_user.this.name
}
