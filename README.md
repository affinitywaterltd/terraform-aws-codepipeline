# AWS CodePipeline Terraform module

Terraform module which creates CodePipeline resources on AWS.

This module focuses on EC2 Instance, EBS Volumes and EBS Volume Attachments.

* [CodePipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline)
* [CodeCommit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codecommit_repository)
* [CodeBuild](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project)
* [CodeDeploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_app)
* [CloudWatch (EventBridge) Event Bus](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_bus)
* [CloudWatch (EventBridge) Event Archive](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_archive)
* [CloudWatch (EventBridge) Event Permission](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_permission)
* [CloudWatch (EventBridge) Event Rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule)
* [CloudWatch (EventBridge) Event Target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target)
* [IAM Role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)
* [IAM Policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)
* [IAM Role Policy Attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)
* [KMS Key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key)
* [KMS Key Alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias)
* [S3 Bucket](https://github.com/affinitywaterltd/terraform-aws-s3)

This Terraform module will provide the required resources for a AWS CodePipeline and all the required resources.

## Terraform versions

Terraform ~> 1.0.0

## Usage

Windows Example with minimum required and useful settings options
```hcl
module "ec2" {
  source        = "github.com/affinitywaterltd/terraform-aws-ec2"
  ami           = local.windows2019_ami
  iam_role      = local.ssm_role
  instance_type = "t3.small"
  user_data     = local.windows_user_data

  subnet_id = local.priv_a
  
  security_groups_ids = [
    local.admin_sg,
    local.remote_access_sg
  ]
  
  root_volume_size = 50
  /*ebs_volumes = [
    {
      size = 2
      type = "gp3"
    },
    {
      size = 3
      type = "gp3"
      iops = 3500 # max 500 per GB (Default 3000)
      throughput = 150 # max 250 (Default 125)
    },
    {
      size = 1 # Defaults to standard if no type is specified
    }
  ]*/
  
  tags = merge(
    local.common_tags,
    {
      "ApplicationType"      = "Application"
      "Name"                 = ""
      "Description"          = ""
      "OperatingSystem"      = "Windows Server 2019"
      "aws_backup_plan_daily_2200_30days" = "true"
      "Schedule"             = "ec2:0800-1700:mon-fri"
      "CreationDate"         = ""
      "ssmMaintenanceWindow" = "aws_week-2_wed_2200"
      "ssmNotification"      = "[email]:[email]:[email]"
    },
  )
}
```

Windows Example with minimum required and useful settings options
```hcl
module "ec2" {
  source        = "github.com/affinitywaterltd/terraform-aws-ec2"
  ami           = local.awslinux2_ami
  iam_role      = local.ssm_role
  instance_type = "t3.small"
  user_data     = local.linux_user_data

  subnet_id = local.priv_a

  security_groups_ids = [
    local.admin_sg,
    local.remote_access_sg
  ]
  
  root_volume_size = 50
  /*ebs_volumes = [
    {
      size = 2
      type = "gp3"
    },
    {
      size = 3
      type = "gp3"
      iops = 3500 # max 500 per GB (Default 3000)
      throughput = 150 # mac 250 (Default 125)
    },
    {
      size = 1 # Defaults to standard if no type is specified
    }
  ]*/

  tags = merge(
    local.common_tags,
    {
      "ApplicationType"      = "Application"
      "Name"                 = ""
      "Description"          = ""
      "OperatingSystem"      = "Amazon Linux 2"
      "aws_backup_plan_daily_2200_30days" = "true"
      "Schedule"             = "ec2:0800-1700:mon-fri"
      "CreationDate"         = ""
      "ssmMaintenanceWindow" = "aws_linux_week-2_wed_2200"
    },
  )
}
```

## Conditional creation

Sometimes you need to have a way to create resources conditionally but Terraform does not allow to use count inside module block, so the solution is to specify argument create_codepipeline.

# Codepipeline will not be created
module "codepipeline" {
  source  = "github.com/affinitywaterltd/terraform-aws-codepipeline"

  create_codepipeline = false
  # ... omitted
}
## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.0.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of Codepipeline project | `string` | `` | yes |
| description | Yeah it's the description | `string` | `""` | yes |
| create_codecommit |Determine whether a codecommit is created | `bool` | `false` | no |
| repo_name | The name of the repository | `string` | `""` | no |
| preconfigured_stage_config | The default pipeline stage configuration to use [See preconfigured options](#Preconfigured_Stage_Configurations) | `string` | `null` | no |
| stages | This list describes each stage of the build | `list(any)` | `[]` | no |
| create_codepipeline | Determine whether a CodePipeline is created | `bool` | `true` | no |
| cross_account_config | [Configuration options below](#cross_account_config) cross account configurations | `any` | `{enabled = false}` | no |
| eventbridge_bus_config | [Configuration options below](#eventbridge_bus_config) cross account event bus configurations | `any` | `{enabled = false}` | no |
| jenkins_config | [Configuration options below](#jenkins_config) Jenkins build server configurations | `any` | `{}` | no |
| regional_artifacts_store | [Configuration options below](#regional_artifacts_store) Provide the configuration for a multi-region pipeline | `any` | `{}` | no |
| codebuild_environment_variables | Provide Environemtn variables to CodeBuild | `any` | `{}` | no |
| cloudformation_template_name | Provide the template filename configuration to CloudFormation | `string` | `"cfn-template.yml"` | no |
| cloudformation_capabilities | Provide the Cabailities configuration to CloudFormation | `string` | `""` | no |
| instance_type | The type of the instance | `string` | `null` | no |
| deployment_region | Provide the configuration for a multi-region pipeline | `string` | `""` | no |
| elasticbeanstalk_environment_name | Provide the configuration for the beanstalk environment name | `string` | `""` | no |
| elasticbeanstalk_application_name | Provide the configuration for the beanstalk application name | `string` | `""` | no |
| cloudformation_iam_role | Determine ARN of the Role used for Cloudformation Deployments | `string` | `""` | no |
| default_logging_bucket | Default S3 bucket logging location | `string` | `null` | yes |
| codedeploy_iam_role | Determine ARN of the Role used for CodeDeploy | `string` | `""` | no |
| codepipeline_iam_role | Determine ARN of the Role used for CodePipeline | `string` | `""` | no |
| codedeploy_compute_platform | Determine which platform codedeploy is using | `string` | `Lambda` | no |
| create_codedeploy | Determine whether a codedeploy is created | `bool` | `false` | no |
| create_codebuild | Determine whether a create_codebuild is created | `bool` | `false` | no |
| force_artifact_destroy | Force the removal of the artifact S3 bucket on destroy (default: false). | `string` | `faslse` | no |
| build_timeout | The time to wait for a CodeBuild to complete before timing out in minutes (default: 5) | `string` | `"60"` | no |
| role | Override for providing a role | `string` | `""` | no |
| bucketname | Overrides the default bucket name with a custom value | `string` | `""` | no |
| defaultbranch | The default git branch. | `string` | `main` | no |
| custom_ecs_cluster | The ECS Cluster name | `string` | `null` | no |
| custom_ecs_service | The ECS Service name | `string` | `null` | no |
| environment | A map to describe the build environment and populate the environment block | `map` | `{privileged_mode = "false", type = "LINUX_CONTAINER", image = "aws/codebuild/standard:5.0", compute_type = "BUILD_GENERAL1_SMALL"}` | no |
| sourcecode | A map to describe where your sourcecode comes from, to fill the sourcecode block in a Codebuild project | `map` | `{type = "CODECOMMIT", location  = "", buildspec = ""}` | no |
| sse_algorithm | The type of encryption algorithm to use | `string` | `"aws:kms"` | no |
| encryption_disabled | Disable the encryption of artifacts | `bool` | `false` | no |
| artifact_type | The Artifact type, S3, CODEPIPELINE or NO_ARTIFACT | `string` | `"S3"` | no |
| artifact_store_type | The Artifact type used in CODEPIPELINE | `string` | `"S3"` | no |
| artifact_store_location | The Artifact location used in CODEPIPELINE | `string` | `""` | no |
| artifact_store | Map to populate the artifact block | `map(any)` | `{}` | no |
| artifact_store_encryption_type | Encryption Type used by CodePipeline Artifacts | `string` | `"KMS"` | no |
| artifact_store_encryption_key_id | Encryption key id used by CodePipeline Artifacts | `string` | `""` | no |
| cloudformation_role_arn | Optionally supply an existing role | `string` | `""` | no |
| codecommit_role_arn | Optionally supply an existing role | `string` | `""` | no |
| cloudformation_iam_policies | Optionally supply IAM policies to add to the Cloudformation Role | `list` | `[]` | no |
| s3_bucket_name | S3 Bucket name used for deployment | `string` | `""` | no |
| tags | A mapping of tags to assign to all resources | `map(string)` | `` | yes |

## cross_account_config
Below are the configuration parameters for cross_account_config
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enabled | Trigger that the cross account configuration is required | `bool` | `false` | no |
| codecommit_role_arn | The IAM Role ARN required to provide access to the code commit repo | `string` | `""` | no |
| assume_role_princpals | IAM roles that will need permissions to assume the codecommit role | `string` | `""` | no |
| s3_bucket_name | The S3 bucket the codecommit role will require access to | `string` | `""` | no |
| codecommit_repo_name | The name of the codecommit repo  | `string` | `number` | no |

## eventbridge_bus_config
Below are the configuration parameters for eventbridge_bus_config
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enabled | Trigger that the event bus configuration is required | `bool` | `false` | no |
| type | Describes whether its the source or desintation eventbus configuration | `string` | `false` | no |
| account_principal | The AWS account ID that the eventbridge will be receiving events from | `string` | `null` | no |
| eventbridge_arn | The ARN of the cross account eventbus to send events | `string` | `null` | no |

## jenkins_config
Below are the configuration parameters for jenkins_config
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_iam_user | Creates IAM user to provide credentials required for Jenkins | `bool` | `false` | yes |
| provider | The provider name as configured in Jenkins | `string` | `""` | no |
| project_name | The project name as configured in Jenkins | `string` | `""` | no |

## Preconfigured_Stage_Configurations
Below describes the bundled pre-configured stage options that can be used for a number of different scenarios requiring less configuration for repeat config types.
* CODECOMMIT_CODEBUILD_ECS
  * Deployment from CodeCommit to ECS without approval
  * Good for non-production usage
* CODECOMMIT_CODEBUILD_APPROVAL_ECS
  * Deployment from CodeCommit to ECS with approval
  * Good for production usage
* CODECOMMIT_CODEBUILD_CLOUDFORMATION
  * Deployment from CodeCommit to a CloudFormation template (ideal for Lambdas, API Gateways and more)  without approval
  * Good for non-production usage
* CODECOMMIT_CODEBUILD_APPROVAL_CLOUDFORMATION
  * Deployment from CodeCommit to a CloudFormation template (ideal for Lambdas, API Gateways and more)  with approval
  * Good for production usage
* CODECOMMIT_JENKINS_ELASTICBEANSTALK
   *  Deployment to ElasticBeanstalk with builds from Jenkins without approval. Must add deployment provider manally for Jenkins
   *  Good for non-production usage
* CODECOMMIT_JENKINS_APPROVAL_ELASTICBEANSTALK
   *  Deployment to ElasticBeanstalk with builds from Jenkins with approval. Must add deployment provider manally for Jenkins
   *  Good for production usage
* CODECOMMIT_S3BUCKET
  * Deployment from CodeCommit straight to an S3 bucket (ideal for static hosted websites)  without approval
  * Good for non-production usage
* CODECOMMIT_APPROVAL_S3BUCKET
  * Deployment from CodeCommit straight to an S3 bucket (ideal for static hosted websites)  with approval
  * Good for production usage

## Outputs

| Name | Description |
|------|-------------|
| artifact_bucket | The S3 bucket name used for the codepipeline artifacts |
| codebuild_role_name | The IAM role name used for codebuild |
| project | The project name used for codebuild |