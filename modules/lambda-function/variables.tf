# Edited by CLAUDE

# --- Required ---

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

# --- Packaging (exactly one of zip or image must be provided) ---

variable "zip" {
  description = "Zip packaging configuration. Provide a local zip file with runtime and handler."
  type = object({
    filename = string
    runtime  = string
    handler  = string
    hash     = optional(string) # Pre-computed base64-encoded SHA256 hash; if omitted, computed from filename
  })
  default = null
}

variable "image" {
  description = "Container image packaging configuration. Provide a pre-built ECR image URI."
  type = object({
    uri               = string
    command           = optional(list(string))
    entry_point       = optional(list(string))
    working_directory = optional(string)
  })
  default = null
}

# --- Optional: Function configuration ---

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = null
}

variable "memory_size" {
  description = "Amount of memory in MB available to the function"
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Function execution timeout in seconds"
  type        = number
  default     = 3
}

variable "architecture" {
  description = "Instruction set architecture (x86_64 or arm64)"
  type        = string
  default     = "x86_64"
}

variable "ephemeral_storage" {
  description = "Size of the /tmp directory in MB (512-10240)"
  type        = number
  default     = 512
}

variable "layers" {
  description = "List of Lambda Layer ARNs to attach"
  type        = list(string)
  default     = []
}

variable "publish" {
  description = "Whether to publish a new version of the Lambda function"
  type        = bool
  default     = false
}

variable "environment_variables" {
  description = "Map of environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions for the function. Set to 0 to throttle (disable). Leave null for unreserved."
  type        = number
  default     = null
}

# --- Optional: Logging ---

variable "log_retention_in_days" {
  description = "CloudWatch Log Group retention in days"
  type        = number
  default     = 7
}

# --- Optional: VPC ---

variable "subnet_ids" {
  description = "List of subnet IDs for VPC configuration"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "List of security group IDs for VPC configuration"
  type        = list(string)
  default     = []
}

# --- Optional: EFS ---

variable "efs_config" {
  description = "EFS mount configuration. When set, mounts an EFS access point into the function at local_mount_path (which must start with /mnt). Requires VPC config (subnet_ids + security_group_ids). The caller is responsible for ensuring EFS mount targets exist in the function's subnets before the function is created (use depends_on)."
  type = object({
    access_point_arn = string
    local_mount_path = string
  })
  default = null

  validation {
    condition     = var.efs_config == null || startswith(var.efs_config.local_mount_path, "/mnt")
    error_message = "efs_config.local_mount_path must start with /mnt (AWS Lambda requirement)."
  }
}

# --- Optional: Additional IAM policies ---

variable "additional_policy_arns" {
  description = "List of additional IAM policy ARNs to attach to the execution role"
  type        = list(string)
  default     = []
}

# --- Optional: Tags ---

variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}
