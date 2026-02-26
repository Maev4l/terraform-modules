# Edited by CLAUDE

# --- Required ---

variable "function_name" {
  description = "Name of the Lambda function (used for resource naming)"
  type        = string
}

variable "function_arn" {
  description = "ARN of the Lambda function"
  type        = string
}

variable "invoke_arn" {
  description = "Invocation ARN of the Lambda function"
  type        = string
}

variable "routes" {
  description = "List of route keys (e.g. [\"GET /users\", \"POST /users\"])"
  type        = list(string)
}

# --- Optional ---

variable "stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
  default     = "$default"
}

variable "custom_domain" {
  description = "Custom domain configuration. Set to null (default) to skip domain setup."
  type = object({
    domain_name     = string
    hosted_zone_id  = string
    certificate_arn = string
  })
  default = null
}

variable "authorizer" {
  description = "JWT authorizer configuration. Set to null (default) to skip authorizer setup. Supports any OIDC provider (Cognito, Auth0, Okta)."
  type = object({
    name             = string
    issuer           = string
    audience         = list(string)
    identity_sources = optional(list(string), ["$request.header.Authorization"])
  })
  default = null
}

variable "cors" {
  description = "CORS configuration. Set to true for permissive defaults, or an object for custom config. Set to null/false to disable."
  type        = any
  default     = null

  validation {
    condition = var.cors == null || var.cors == false || var.cors == true || (
      try(var.cors.allow_origins, null) != null
    )
    error_message = "cors must be null, false, true, or an object with allow_origins."
  }
}

variable "disable_execute_api_endpoint" {
  description = "Whether to disable the default execute API endpoint. Set to true to force traffic through custom domain only."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}
