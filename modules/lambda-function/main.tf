# Edited by CLAUDE

locals {
  has_vpc = length(var.subnet_ids) > 0 && length(var.security_group_ids) > 0

  # Packaging mode
  is_zip   = var.zip != null
  is_image = var.image != null
  has_image_config = local.is_image && (
    var.image.command != null ||
    var.image.entry_point != null ||
    var.image.working_directory != null
  )
  has_efs = var.efs_config != null
}

resource "aws_lambda_function" "this" {
  function_name                  = var.function_name
  role                           = aws_iam_role.this.arn
  description                    = var.description
  memory_size                    = var.memory_size
  timeout                        = var.timeout
  publish                        = var.publish
  reserved_concurrent_executions = var.reserved_concurrent_executions
  layers                         = local.is_zip ? var.layers : []

  # Packaging mode
  package_type = local.is_zip ? "Zip" : "Image"
  filename     = local.is_zip ? var.zip.filename : null
  runtime      = local.is_zip ? var.zip.runtime : null
  handler      = local.is_zip ? var.zip.handler : null
  # Use provided hash if available, otherwise compute from filename
  source_code_hash = local.is_zip ? coalesce(var.zip.hash, filebase64sha256(var.zip.filename)) : null
  image_uri        = local.is_image ? var.image.uri : null

  architectures = [var.architecture]

  ephemeral_storage {
    size = var.ephemeral_storage
  }

  dynamic "image_config" {
    for_each = local.has_image_config ? [1] : []

    content {
      command           = var.image.command
      entry_point       = var.image.entry_point
      working_directory = var.image.working_directory
    }
  }

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []

    content {
      variables = var.environment_variables
    }
  }

  dynamic "vpc_config" {
    for_each = local.has_vpc ? [1] : []

    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  dynamic "file_system_config" {
    for_each = local.has_efs ? [1] : []

    content {
      arn              = var.efs_config.access_point_arn
      local_mount_path = var.efs_config.local_mount_path
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.this,
  ]

  tags = var.tags

  lifecycle {
    precondition {
      condition     = (var.zip != null) != (var.image != null)
      error_message = "Exactly one of 'zip' or 'image' must be provided."
    }

    precondition {
      condition     = !local.has_efs || local.has_vpc
      error_message = "efs_config requires VPC configuration (both subnet_ids and security_group_ids must be set)."
    }
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_in_days
  tags              = var.tags
}
