data "aws_iam_policy_document" "deployer" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals = {
      type = "AWS"

      identifiers = ["arn:aws:iam::047969882937:role/cd-gsp-concourse-worker"]
    }
  }
}

resource "aws_iam_role" "deployer" {
  name = "deployer"

  assume_role_policy = "${data.aws_iam_policy_document.deployer.json}"
}

resource "aws_iam_role_policy_attachment" "deployer" {
  role       = "${aws_iam_role.deployer.name}"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
