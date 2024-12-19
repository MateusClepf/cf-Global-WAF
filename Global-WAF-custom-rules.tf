# Baseline ruleset applied to all accounts
locals {
  baseline_ruleset = [
   {
      action      = "block"
      expression  = "(http.request.uri.path ~ \"^/wp-admin\" and ip.src ne 192.0.2.1)"
      description = "Global rules 1: Block access to wp-admin except for specific IP"
    },
    {
      action      = "managed_challenge"
      expression  = "(http.user_agent contains \"BadBot\")"
      description = "Global rules 2: Challenge requests from known bad bots"
    },
    {
      action      = "log"
      expression  = "ip.src in {192.0.2.0/24}"
      description = "Global rules 3: Log traffic from trusted subnet"
    },
    {
      action      = "block"
      expression  = "(http.request.uri.path in {\"/login\" \"/register\"})"
      description = "Global rules 4: Block access to sensitive endpoints"
    },
    {
      action      = "skip"
      expression  = "(http.request.uri.path in {\"/skip-this\" \"/and-this\"})"
      description = "Global rules 5: Skip rules for specific paths"
      action_parameters = {
        ruleset    = "current"
        phases     = ["http_ratelimit","http_request_firewall_managed","http_request_sbfm"]
        products   = ["zoneLockdown","bic","uaBlock","hot","securityLevel","rateLimit","waf"]
      }
      logging  = {
        enabled = true
      }
    }
  ]
}
