output "cross_account_role_arn" {
  value = aws_iam_role.cross_account_role.arn
}
output "cross_account_role_name" {
  value = aws_iam_role.cross_account_role.name
}
output "materialization_cross_role_arn" {
  value = aws_iam_role.materialization_cross_account_role.arn
}
output "materialization_cross_role_name" {
  value = aws_iam_role.materialization_cross_account_role.name
}
