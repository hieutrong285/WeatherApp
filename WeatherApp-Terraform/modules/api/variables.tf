variable "lambda_authorizer_filename" {
  description = "The filename of the Lambda authorizer zip file."
  type        = string
}

variable "region" {
    type = string
    default = "us-east-1"
}
