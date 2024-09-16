variable "ami_id" {
  description = "The AMI ID for the instance"
  default     = "ami-0e86e20dae9224db8"
}

variable "instance_type" {
  description = "The instance type for the lumiwealth server"
  default     = "t2.micro"
}

variable "key_name" {
  description = "The name of the SSH key pair"
  default     = "lumiw"
}

variable "script_file" {
  description = "The name of the bash script to run"
  default     = "setup.sh"
}

variable "code_name" {
  description = "The name of the code in s3 bucket"
  default     = "crypto_double_ema_trending"

  validation {
    condition     = contains(["crypto_double_ema_trending", "crypto_bbands_v2", "crypto_custom_etf", "diversified_leverage_with_threshold", "stock_top_etf_picker" ], var.code_name)
    error_message = "The code_name is wrong, check spelling."
  }
}
