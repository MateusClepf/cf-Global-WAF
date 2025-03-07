# Merge baseline managed ruleset with per-account overrides
locals {
  rulesets_per_account_managed = {
    for account, config in local.accounts : account => merge(
      {
        rules = concat( config.override_managed_rules,local.baseline_ruleset_managed)
      }
    )
  }
}


#Create the ruleset entrypoint for each account
resource "cloudflare_ruleset" "Global-WAF-Managed-phase-entrypoint" {
  for_each    = local.accounts
  account_id  = each.value.account_id
  kind       = "root"
  name       = "root"
  phase      = "http_request_firewall_managed"
  
# Override rules (passed from the root module per account) come first
  dynamic "rules" {
    for_each = local.rulesets_per_account_managed[each.key].rules
    content {
      action      = rules.value.action
      expression  = rules.value.expression
      description = rules.value.description
      enabled = try(rules.value.enabled,null)
      // Handle action_parameters gracefully

      # For action_parameters - this should be a single block if present
      dynamic "action_parameters" {
        for_each = can(rules.value.action_parameters) ? [rules.value.action_parameters] : []
        content {
          id = try(action_parameters.value.id, null)
          ruleset = try(action_parameters.value.ruleset, null)
          
          # Handle overrides if they exist
          dynamic "overrides" {
            for_each = can(action_parameters.value.overrides) ? [action_parameters.value.overrides] : []
            content {
              # Instead of trying to iterate through rules and categories as lists,
              # let's generate them individually based on your data structure
              dynamic "rules" {
                for_each = try(action_parameters.value.overrides.rules_list, {})
                content {
                  id = try(rules.value.id, null)
                  action = try(rules.value.action, null)
                  enabled = try(rules.value.enabled, null)
                  score_threshold = try(rules.value.score_threshold, null)
                }
              }

              
              # For each categories entry in your data
              dynamic "categories" {
                for_each = try(action_parameters.value.overrides.categories_list, {})
                # This assumes categories is a map with keys like "category1", "category2", etc.
                content {
                  category = try(categories.value.category, null)
                  action = try(categories.value.action, null)
                  enabled = try(categories.value.enabled, null)
                }
              }
            }
          }
        }
      }
      
      # For logging - this is a single block if present
      dynamic "logging" {
        for_each = can(rules.value.logging) ? [rules.value.logging] : []
        content {
          enabled = logging.value.enabled
        }
      }
    }
  }
}





/* #how the same rules would look like with standard terraform configuraiton
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
      id = "efb7b8c949ac4650a09736fc376e9aee" #Cloudflare Managed Ruleset ID - this ID is fixed
      overrides { #overrides examples from https://developers.cloudflare.com/terraform/additional-configurations/waf-managed-rulesets/#configure-overrides
        rules {
          id      = "5de7edfa648c4d6891dc3e7f84534ffa"
          action  = "log"
          enabled = true
        }
        rules {
          id      = "75a0060762034a6cb663fd51a02344cb"
          enabled = false
        }
        categories {
          category = "wordpress"
          action   = "js_challenge"
          enabled  = true
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
      id = "4814384a9e5d4991b9815dcfc25d2f1f" #Cloudflare OWASP Core Ruleset ID  - this ID is fixed
      #Paranoia level is set by disabling the upper level, example below sets paranoia level to 2
      overrides {
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
      }

    }
    expression  = "(cf.zone.plan eq \"ENT\")"
    description = "TF Global OWASP"
    enabled     = true
  }
}
*/
