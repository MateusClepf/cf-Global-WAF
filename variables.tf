variable "ruleset_name" {
  description = "Name of the ruleset"
  type        = string
  default     = "Global Account WAF ruleset"
}

variable "ruleset_description" {
  description = "Description of the ruleset"
  type        = string
  default     = "Global baseline WAF custom ruleset"
}
