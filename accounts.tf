locals {
  accounts = {
    account_1 = {
        account_id     = "821e6e32be9bcae169a6035384c75210"
        name           = "Account1"
                #Example account level custom rule override
        override_custom_rules = [
            {
                action      = "skip"
                expression  = "(http.request.uri.path ~ \"^/bypass\")"
                description = "TF - Local overwrite 1: Skip rules for the /bypass path"
                action_parameters = {
                    ruleset    = "current"
                    products   = ["zoneLockdown","bic","uaBlock","hot","securityLevel","rateLimit","waf"]
                    phases     = ["http_ratelimit","http_request_firewall_managed","http_request_sbfm"]
                }
                logging  = {
                    enabled = true
                }
            }
        ]
        #Example account level managed rule override
        override_managed_rules = [
            {
                action = "skip"
                action_parameters = {
                    ruleset = "current"
                }
                logging= {
                    enabled = true
                }
                expression  = "(http.request.uri.path eq \"/skip\") and (cf.zone.plan eq \"ENT\")"
                description = "TF - Local override 1: managed ruleset"
            }
        ]
        #Rate limit rules don't have a skip concept, you would use custom WAF rules to skip rate limit rules.
        #You could potentially use this override to create account specific rate limit rules.
        override_ratelimit_rules = [
            {
                ref         = "rate_limit_signup_ip_nat"
                description = "Rate limit sign up endpoint requests by IP with NAT support"
                expression  = "http.request.uri.path contains \"/signup/\""
                action      = "block"
                ratelimit = {
                    characteristics     = ["cf.colo.id", "cf.unique_visitor_id"]
                    period              = 60
                    requests_per_period = 100
                    mitigation_timeout  = 600
                }
            }
        ] 
    }
    # Add additional accounts here...
    account_2 = {
        account_id     = "3c7221c17cf33199d13d83b67a05028c"
        name           = "Account2"
        override_custom_rules = []
        override_managed_rules = []
        override_ratelimit_rules = []
    }
  }

}