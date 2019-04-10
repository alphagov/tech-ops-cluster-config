resource "aws_iam_role" "admin" {
  name = "admin"

  assume_role_policy = "${data.aws_iam_policy_document.grant-iam-admin-policy.json}"
}

resource "aws_iam_role_policy_attachment" "admin-attach" {
  role       = "${aws_iam_role.admin.name}"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "aws_iam_policy_document" "grant-iam-admin-policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals = {
      type = "AWS"

      identifiers = "${concat(var.additional_admins, list(
        "arn:aws:iam::622626885786:user/sam.crang@digital.cabinet-office.gov.uk",
        "arn:aws:iam::622626885786:user/daniel.blair@digital.cabinet-office.gov.uk",
        "arn:aws:iam::622626885786:user/chris.farmiloe@digital.cabinet-office.gov.uk",
        "arn:aws:iam::622626885786:user/rafal.proszowski@digital.cabinet-office.gov.uk",
        "arn:aws:iam::622626885786:user/david.pye@digital.cabinet-office.gov.uk",
        "arn:aws:iam::622626885786:user/stephen.ford@digital.cabinet-office.gov.uk",
        "arn:aws:iam::622626885786:user/david.povey@digital.cabinet-office.gov.uk",
        "arn:aws:iam::622626885786:user/david.mcdonald@digital.cabinet-office.gov.uk",
        "arn:aws:iam::622626885786:user/toby.lornewelch-richards@digital.cabinet-office.gov.uk",
      ))}"
    }

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = ["${concat(var.additional_cidrs, var.office_cidrs)}"]
    }
  }
}

output "admin-role-arn" {
  value = "${aws_iam_role.admin.arn}"
}
