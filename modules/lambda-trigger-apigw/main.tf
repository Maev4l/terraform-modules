# Edited by CLAUDE

locals {
  # Flatten { int_key => { routes = [...] } } into a map keyed by "int_key:route"
  # so each (integration, route) pair can be a distinct resource via for_each.
  # WHY: HTTP API routes are unique per (method, path), but we need one route
  # resource per (integration, route) pair so each route can target a different Lambda.
  route_pairs = merge([
    for int_key, int in var.integrations : {
      for route in int.routes :
      "${int_key}:${route}" => {
        integration_key = int_key
        route_key       = route
      }
    }
  ]...)
}

resource "aws_apigatewayv2_api" "this" {
  name                         = "${var.api_name}-http-api"
  protocol_type                = "HTTP"
  disable_execute_api_endpoint = var.disable_execute_api_endpoint
  tags                         = var.tags

  dynamic "cors_configuration" {
    for_each = local.cors_enabled ? [local.cors_config] : []

    content {
      allow_origins     = cors_configuration.value.allow_origins
      allow_methods     = cors_configuration.value.allow_methods
      allow_headers     = cors_configuration.value.allow_headers
      expose_headers    = cors_configuration.value.expose_headers
      max_age           = cors_configuration.value.max_age
      allow_credentials = cors_configuration.value.allow_credentials
    }
  }
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.stage_name
  auto_deploy = true
  tags        = var.tags
}

# One integration per entry in var.integrations — fan-out over multiple Lambdas
# behind a single HTTP API.
resource "aws_apigatewayv2_integration" "this" {
  for_each = var.integrations

  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = each.value.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# One route per (integration, route) pair. local.route_pairs flattens the
# nested structure so each METHOD /path across all integrations becomes a
# distinct route targeting the correct integration.
resource "aws_apigatewayv2_route" "this" {
  for_each = local.route_pairs

  api_id             = aws_apigatewayv2_api.this.id
  route_key          = each.value.route_key
  target             = "integrations/${aws_apigatewayv2_integration.this[each.value.integration_key].id}"
  authorization_type = local.create_authorizer ? "JWT" : "NONE"
  authorizer_id      = local.create_authorizer ? aws_apigatewayv2_authorizer.this[0].id : null
}

# One Lambda permission per integration. statement_id must be unique per
# function per principal+source combo, so we key it by the integration name.
resource "aws_lambda_permission" "this" {
  for_each = var.integrations

  statement_id  = "AllowAPIGatewayInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
