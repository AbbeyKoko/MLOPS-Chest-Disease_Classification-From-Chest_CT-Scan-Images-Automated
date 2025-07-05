data "aws_iam_user" "terraform-user" {
  user_name = "terraform-user"
}

resource "aws_iam_access_key" "terraform-user_key" {
  user = data.aws_iam_user.terraform-user.user_name
}