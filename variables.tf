  data "aws_caller_identity" "current" {}

data "aws_iam_role" "existing" {
  count = var.role == "" ? 0 : 1
  name  = var.role
}

data "aws_region" "current" {}

locals {
  bucket     = "${var.name}-${data.aws_caller_identity.current.account_id}-artifacts"
  bucketname = var.bucketname == "" ? local.bucket : var.bucketname
}

locals {
  codepipeline_role_arn = var.codepipeline_iam_role == "" &&  var.create_codepipeline ? element(concat(aws_iam_role.pipeline.*.arn, list("")), 0) : var.codepipeline_iam_role
  codedeploy_role_arn = var.codedeploy_iam_role == "" ? element(concat(aws_iam_role.pipeline.*.arn, list("")), 0) : var.codedeploy_iam_role
  cloudformation_role_arn = var.cloudformation_iam_role == "" ? element(concat(aws_iam_role.cloudformation.*.arn, list("")), 0) : var.cloudformation_iam_role
  codecommit_role_arn = var.codecommit_role_arn == "" ? element(concat(aws_iam_role.AWSCodeCommitRoleCrossAccount.*.arn, list("")), 0) : var.codecommit_role_arn

  codecommit_repo_arn = var.create_codecommit && var.codecommit_repo_name == "" ? aws_codecommit_repository.this.0.arn : var.codecommit_repo_name
}

variable "cloudformation_iam_role"{
  description = "Determine ARN of the Role used for Cloudformation Deployments"
  type = string
  default = ""
}

variable "cloudformation_region"{
  description = "Set the region to deploy Cloudformation resources"
  type = string
  default = ""
}


variable "default_logging_bucket"{
  description = "Default S3 bucket logging location"
  type = string
  default = null
}

variable "codedeploy_iam_role"{
  description = "Determine ARN of the Role used for CodeDeploy"
  type = string
  default = ""
}

variable "codepipeline_iam_role"{
  description = "Determine ARN of the Role used for CodePipeline"
  type = string
  default = ""
}

variable "enable_cross_account_role"{
  description = "Determine If a cross account IAM role is created"
  type = bool
  default = false
}

variable "cross_account_role_account_princpals"{
  description = "Supply the account ids used if a cross account IAM role is created"
  type = list(string)
  default = []
}

variable "cross_account_kms_key"{
  description = "Supply the KMS Key used if a cross account S3 is required"
  type = string
  default = ""
}

variable "cross_account_s3_bucket_name"{
  description = "Supply the S3 bucket to output cross account artifacts"
  type = string
  default = ""
}

variable "create_codecommit"{
  description = "Determine whether a codecommit is created"
  type = bool
  default = false
}

variable "codecommit_repo_name"{
  description = "Determine the codecommit repo to reference"
  type = string
  default = ""
}

variable "codedeploy_compute_platform"{
  description = "Determine which platform codedeploy is using"
  type = string
  default = "Lambda"
}

variable "create_codedeploy"{
  description = "Determine whether a codedeploy is created"
  type = bool
  default = false
}

variable "create_codepipeline"{
  description = "Determine whether a CodePipeline is created"
  type = bool
  default = true
}

variable "create_codebuild"{
  description = "Determine whether a CodeBuild is created"
  type = bool
  default = false
}

variable "reponame" {
  type        = string
  description = "The name of the repository"
  default     = ""
}

variable "force_artifact_destroy" {
  type        = string
  description = "Force the removal of the artifact S3 bucket on destroy (default: false)."
  default     = false
}

variable "build_timeout" {
  description = "The time to wait for a CodeBuild to complete before timing out in minutes (default: 5)"
  type        = string
  default     = "60"
}

variable "role" {
  description = "Override for providing a role"
  default     = ""
  type        = string
}

variable "artifact" {
  description = "Populates the Artifact block"
  default = {
    packaging      = "NONE"
    namespace_type = "NONE"
  }
}

variable "projectroot" {
  description = "The name of the parent project for SSM"
  type        = string
  default     = "core"
}

variable "description" {
  description = "Yeah it's the description"
  type        = string
  default     = ""
}

variable "bucketname" {
  description = ""
  default     = ""
  type        = string
}

variable "defaultbranch" {
  description = "The default git branch"
  type        = string
  default     = "main"
}

variable "custom_ecs_cluster" {
  description = "The ECS Cluster name"
  type        = string
  default     = null
}

variable "custom_ecs_service" {
  description = "The ECS Service name"
  type        = string
  default     = null
}

variable "environment" {
  description = "A map to describe the build environment and populate the environment block"
  type        = map
  default = {
    privileged_mode = "false"
    type            = "LINUX_CONTAINER"
    image           = "aws/codebuild/standard:5.0"
    compute_type    = "BUILD_GENERAL1_SMALL"
  }
}


variable "sourcecode" {
  description = "A map to describe where your sourcecode comes from, to fill the sourcecode block in a Codebuild project "
  type        = map
  default = {
    type      = "CODECOMMIT"
    location  = ""
    buildspec = ""
  }
}

variable "sse_algorithm" {
  description = "The type of encryption algorithm to use"
  type        = string
  default     = "aws:kms"
}


variable "encryption_disabled" {
  description = "Disable the encryption of artifacts"
  type        = bool
  default     = false
}

variable "artifact_type" {
  description = "The Artifact type, S3, CODEPIPELINE or NO_ARTIFACT"
  type        = string
  default     = "S3"
}

variable "artifact_store_type" {
  description = "The Artifact type used in CODEPIPELINE"
  type        = string
  default     = "S3"
}

variable "artifact_store_location" {
  description = "The Artifact location used in CODEPIPELINE"
  type        = string
  default     = ""
}

variable "versioning" {
  type        = bool
  description = "Set bucket to version"
  default     = false
}

variable "mfa_delete" {
  type        = bool
  description = "Require MFA to delete"
  default     = false
}


variable "artifact_store" {
  description = "Map to populate the artifact block"
  type        = map(any)
  default     = {}
}

variable "name" {
  type = string
}

variable "role_arn" {
  type        = string
  description = "Optionally supply an existing role"
  default     = ""
}

variable "cloudformation_role_arn" {
  type        = string
  description = "Optionally supply an existing role"
  default     = ""
}

variable "codecommit_role_arn" {
  type        = string
  description = "Optionally supply an existing role"
  default     = ""
}

variable "cloudformation_iam_policies" {
  type        = list
  description = "Optionally supply IAM policies to add to teh Cloudformation Role"
  default     = []
}

variable "stages" {
  type        = list(any)
  description = "This list describes each stage of the build"
  default     = []
}

variable "preconfigured_stage_config" {
  type        = string
  description = "The default pipeline stage configuration to use"
  default     = null
}


variable "tags" {
  type        = map(any)
  description = "Implements the common tags scheme"
}

variable "policypath" {
  default     = ""
  type        = string
  description = ""
}

variable "artifact_store_encryption_type" {
  description     = "Encryption Type used by CodePipeline Artifacts"
  type        = string
  default = "KMS"
}

variable "artifact_store_encryption_key_id" {
  description     = "Encryption key id used by CodePipeline Artifacts"
  type        = string
  default = ""
}