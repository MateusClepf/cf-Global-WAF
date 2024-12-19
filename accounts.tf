locals {
  accounts = {
    account_1 = {
        account_id     = "821e6e32be9bcae169a6035384c75210"
        name           = "Account1"
        override_rules = []
    }
    # Add additional accounts here...
    account_2 = {
        account_id     = "3c7221c17cf33199d13d83b67a05028c"
        name           = "Account2"
        #Example account level override
        override_rules = [
        {
            action      = "skip"
            expression  = "(http.request.uri.path ~ \"^/bypass\")"
            description = "Local overwrite 1: Skip rules for the /bypass path"
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
    }
  }

}