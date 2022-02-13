
output "cluster" {
  value = {
    arn : aws_iam_role.cluster.arn
  }
}

output "node_group" {
  value = {
    arn : aws_iam_role.node_group.arn
  }
}
