resource "aws_codecommit_repository" "this" {
  count = var.create_codecommit ? 1 : 0

  repository_name = var.reponame
  description     = var.description

  tags =  var.common_tags
}