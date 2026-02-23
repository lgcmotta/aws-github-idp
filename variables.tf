variable "aws" {
  type = object({
    bucket = string
    key    = string
    region = string
    tags   = map(string)
  })
  description = "AWS settings to manage state on S3 and automatically apply tags"
}

variable "github" {
  type = object({
    url = string
  })
  description = "GitHub OIDC IDP settings"
}
