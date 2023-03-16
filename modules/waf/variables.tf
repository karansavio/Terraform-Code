variable "ipset_name" {
  type    = string
  default = "tfIPSet"

}

variable "ip_address_version" {
  type    = string
  default = "IPV4"

}

variable "scope" {
  type    = string
  default = "REGIONAL"

}

variable "ip_addresses" {
  type    = set(string)
  default = ["192.0.7.0/24"]

}

variable "managed_rules" {
  type = list(object({
    name            = string
    priority        = number
    override_action = string
    excluded_rules  = list(string)
    vendor_name     = string
  }))
  description = "List of WAF rules for OWASP Top 10 attacks"
  default = [{
    name            = "AWSManagedRulesCommonRuleSet"
    priority        = 1
    override_action = "block"
    excluded_rules  = []
    vendor_name     = "AWS"
    },
    {
      name            = "AWSManagedRulesSQLiRuleSet"
      priority        = 2
      override_action = "block"
      excluded_rules  = []
      vendor_name     = "AWS"
    },
    {
      name            = "AWSManagedRulesKnownBadInputsRuleSet"
      priority        = 3
      override_action = "block"
      excluded_rules  = []
      vendor_name     = "AWS"
  }]
}

variable "default_action" {
  type        = string
  description = "The action to perform if none of the rules contained in the WebACL match."
  default     = "allow"
}
