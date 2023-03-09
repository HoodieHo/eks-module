data "aws_iam_policy_document" "app-policy" {
  for_each = var.app_roles
  dynamic "statement" {
    for_each = toset(each.value.permissions)
    content {
      actions   = lookup(statement.value, "actions")
      resources = lookup(statement.value, "resources")
    }
  }
}

resource "aws_iam_role_policy" "app-policy" {
  for_each = var.app_roles
  name     = format("%s-permissions", each.key)
  role     = aws_iam_role.app[each.key].name
  policy   = data.aws_iam_policy_document.app-policy[each.key].json
}

data "aws_iam_policy_document" "app-assume" {
  for_each = var.app_roles
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }
    condition {
      test     = "StringEquals"
      variable = format("%s:sub", replace(aws_iam_openid_connect_provider.this.url, "https://", ""))
      values = [
        format("system:serviceaccount:${each.value.namespace}:${each.value.serviceaccount}")
      ]
    }
  }
}

resource "aws_iam_role" "app" {
  for_each           = var.app_roles
  name               = format("role-%s-%s", var.cluster_name, each.key)
  assume_role_policy = data.aws_iam_policy_document.app-assume[each.key].json
  tags               = var.tags
}