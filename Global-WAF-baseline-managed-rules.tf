# Baseline ruleset applied to all accounts
locals {
  baseline_ruleset_managed = [
    {  # Account-level WAF Managed Ruleset exception
      action = "skip"
      action_parameters = {
          ruleset = "current"
      }
      logging = {
          enabled = true
      }
      expression  = "(http.request.uri.path eq \"/skip\") and (cf.zone.plan eq \"ENT\")"
      description = "TF - Global Skip all managed ruleset"
    },
    { #Cloudflare Managed Ruleset
      action = "execute"
      action_parameters = {
        id = "efb7b8c949ac4650a09736fc376e9aee" #Cloudflare Managed Ruleset ID - this ID is fixed
        overrides = { #overrides examples from https://developers.cloudflare.com/terraform/additional-configurations/waf-managed-rulesets/#configure-overrides
          rules_list = [
            {
              id      = "5de7edfa648c4d6891dc3e7f84534ffa"
              action  = "log"
              enabled = true
            },
            {
              id      = "75a0060762034a6cb663fd51a02344cb"
              enabled = false
            }
          ],
          categories_list = [
            {
              category = "wordpress"
              action   = "js_challenge"
              enabled  = true
            }
          ]
        }
      }
      expression  = "((http.host contains \"www.whereismypacket.net\")) and (cf.zone.plan eq \"ENT\")"
      description = "TF - Global managed WAF"
      enabled     = true
    },
    { #Cloudflare OWASP Core Ruleset
      action = "execute"
      action_parameters = {
        id = "4814384a9e5d4991b9815dcfc25d2f1f" #Cloudflare OWASP Core Ruleset ID  - this ID is fixed
        #Paranoia level is set by disabling the upper level, example below sets paranoia level to 2
        overrides = {
          categories_list = [
            {
              category = "paranoia-level-3"
              enabled   = "false"
            },
            {
              category = "paranoia-level-4"
              enabled   = "false"
            }
          ],
          rules_list = [
            {
              id = "6179ae15870a4bb7b2d480d4843b323c"
              score_threshold = "60"
              action = "managed_challenge"
            },
            {
              id = "8ac8bc2a661e475d940980f9317f28e1"
              enabled = "false"
            }
          ]
        }

      }
      expression  = "(cf.zone.plan eq \"ENT\")"
      description = "TF - Global OWASP"
      enabled     = true
    }
  ]
}
