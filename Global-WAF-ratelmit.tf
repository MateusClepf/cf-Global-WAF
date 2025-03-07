

# Merge baseline ruleset with per-account overrides
locals {
  rulesets_per_account_ratelimit = {
    for account, config in local.accounts : account => merge(
      {
        rules = concat( config.override_ratelimit_rules,local.baseline_ruleset_ratelimit)
      }
    )
  }
}

# Create rulesets for each account
resource "cloudflare_ruleset" "Global-WAF-Ratelimit-ruleset" {
  for_each    = local.accounts
  name        = "Global baseline WAF Ratelimit ruleset"
  description = "Global baseline WAF Ratelimit ruleset"
  phase       = "http_ratelimit"
  kind        = "custom"
  account_id  = each.value.account_id

# Override rules (passed from the root module per account) come first
  dynamic "rules" {
    for_each = local.rulesets_per_account_ratelimit[each.key].rules
    content {
      action      = rules.value.action
      expression  = rules.value.expression
      description = rules.value.description
      ref = rules.value.ref
      enabled = try(rules.value.enabled,null)
      // Handle action_parameters gracefully

      # For action_parameters - this should be a single
      dynamic "action_parameters" {
        for_each = can(rules.value.action_parameters) ? [rules.value.action_parameters] : []
        content {
          # Handle overrides if they exist
          dynamic "response" {
            for_each = can(action_parameters.value.response) ? [action_parameters.value.response] : []
            content {
              status_code = try(response.value.status_code, null)
              content = try(response.value.content, null)
              content_type = try(response.value.content_type, null)
            }
          }
        }

      }

      # For ratelimit - this should be a single block
      dynamic "ratelimit" {
        for_each = can(rules.value.ratelimit) ? [rules.value.ratelimit] : []
        content {
          characteristics = try(ratelimit.value.characteristics, null)
          period = try(ratelimit.value.period, null)
          requests_per_period = try(ratelimit.value.requests_per_period, null)
          mitigation_timeout = try(ratelimit.value.mitigation_timeout, null)
          counting_expression = try(ratelimit.value.counting_expression, null)
        }
        
      }
    }
  }
}

#Create the ruleset entrypoint for each account
resource "cloudflare_ruleset" "Global-WAF-Ratelimit-phase-entrypoint" {
  for_each    = local.accounts
  account_id  = each.value.account_id
  kind       = "root"
  name       = "Global-WAF-Ratelimit-phase-entrypoint"
  phase      = "http_ratelimit"
  rules {
    action = "execute"
    action_parameters {
      id      = cloudflare_ruleset.Global-WAF-Ratelimit-ruleset[each.key].id
      //version = "latest"
    }
    description  = "Global-WAF-Ratelimit-phase-entrypoint"
    enabled      = true
    expression   = "(cf.zone.plan eq \"ENT\")"
  }
}


