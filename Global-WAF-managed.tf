# As managed rulesets already exist you only need to reference their IDs
data "cloudflare_rulesets" "example_rulesets" {
  for_each    = local.accounts
  account_id = each.value.account_id
}

#Create the ruleset entrypoint for each account
resource "cloudflare_ruleset" "Global-WAF-Custom-phase-entrypoint-managed" {
  for_each    = local.accounts
  account_id  = each.value.account_id
  kind       = "root"
  name       = "root"
  phase      = "http_request_firewall_managed"
  
  # Account-level WAF Managed Ruleset exception
  rules {
    action = "skip"
    action_parameters {
        ruleset = "current"
    }
    logging {
        enabled = true
        }
    expression  = "(http.request.uri.path eq \"/skip\") and (cf.zone.plan eq \"ENT\")"
    description = "TF-Skip all managed ruleset"
  }
  #Cloudflare Managed Ruleset
  rules {
    action = "execute"
    action_parameters {
      id = "efb7b8c949ac4650a09736fc376e9aee" #Cloudflare Managed Ruleset ID
      overrides {
        categories {
          category = "wordpress"
          action   = "block"
          enabled   = "true"
        }

        categories {
          category = "joomla"
          action   = "block"
          enabled   = "true"
        }
      }
    }
    expression  = "((http.host contains \"www.whereismypacket.net\")) and (cf.zone.plan eq \"ENT\")"
    description = "TF Global managed WAF"
    enabled     = true
  }
  #Cloudflare OWASP Core Ruleset
  rules {
    action = "execute"
    action_parameters {
      id = "4814384a9e5d4991b9815dcfc25d2f1f" #Cloudflare OWASP Core Ruleset ID
      #Paranoia level is set by disabling the upper level, example below sets paranoia level to 2
      /*overrides {
        categories {
          category = "paranoia-level-3"
          enabled   = "false"
        }
        categories {
          category = "paranoia-level-4"
          enabled   = "false"
        }
        rules {
          id = "6179ae15870a4bb7b2d480d4843b323c"
          score_threshold = "60"
          action = "managed_challenge"
        }
        rules {
          id = "8ac8bc2a661e475d940980f9317f28e1"
          enabled = "false"
        }
      }*/

    }
    expression  = "(cf.zone.plan eq \"ENT\")"
    description = "TF Global OWASP"
    enabled     = true
  }
}


