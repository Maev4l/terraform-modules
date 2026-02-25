# Edited by CLAUDE

output "api_id" {
  description = "ID of the HTTP API"
  value       = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "Default API Gateway endpoint URL"
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "execution_arn" {
  description = "Execution ARN of the HTTP API"
  value       = aws_apigatewayv2_api.this.execution_arn
}

output "stage_id" {
  description = "ID of the API Gateway stage"
  value       = aws_apigatewayv2_stage.this.id
}

output "custom_domain_url" {
  description = "Custom domain URL (null if no custom domain configured)"
  value       = local.create_domain ? "https://${var.custom_domain.domain_name}" : null
}

output "authorizer_id" {
  description = "ID of the JWT authorizer (null if no authorizer configured)"
  value       = local.create_authorizer ? aws_apigatewayv2_authorizer.this[0].id : null
}
