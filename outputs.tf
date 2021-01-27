output "artifact_bucket" {
  value = local.bucketname
}

output "codebuild_role_name" {
  value = var.role == "" ? element(concat(aws_iam_role.codebuild.*.id, list("")), 0) : var.role
}

output "project" {
  value = element(concat(aws_codebuild_project.this.*.id, list("")), 0)
}