module "api" {
  source = "../../modules/api"

  weather_authorizer  = var.weather_authorizer
  lambda_authorizer_filename  = var.lambda_authorizer_filename
  weather_api = var.weather_api
  region   = var.region
  function_name   = var.function_name
  default_tags    = var.default_tags
}
