

# Merge baseline ruleset with per-account overrides
locals {
  rulesets_per_account = {
    for account, config in local.accounts : account => merge(
      {
        rules = concat( config.override_rules,local.baseline_ruleset)
      }
    )
  }
}

# Create rulesets for each account
resource "cloudflare_ruleset" "Global-account-waf-ruleset" {
  for_each    = local.accounts
  name        = var.ruleset_name
  description = var.ruleset_description
  phase       = "http_request_firewall_custom"
  kind        = "custom"
  account_id  = each.value.account_id

# Override rules (passed from the root module per account) come first
  dynamic "rules" {
    for_each = local.rulesets_per_account[each.key].rules
    content {
      action      = rules.value.action
      expression  = rules.value.expression
      description = rules.value.description

      // Handle action_parameters gracefully

      dynamic  "action_parameters" {
        //Check if action_parameters exits in the rule, if not, don't create the block using ternary operator 
        for_each = can(rules.value.action_parameters) ? [1] : []
        content {
          ruleset = try(rules.value.action_parameters.ruleset,null)
          phases = try(rules.value.action_parameters.phases,null)
          products = try(rules.value.action_parameters.products,null)
        }

      }
      dynamic  "logging" {
        //Check if logging exits in the rule, if not, don't create the block ternary operator 
        for_each = can(rules.value.logging) ? [1] : []
        content {
          enabled = rules.value.logging.enabled

        }

      }
    }
  }
}


#Create the ruleset entrypoint for each account
resource "cloudflare_ruleset" "Global-WAF-Custom-phase-entrypoint" {
  for_each    = local.accounts
  account_id  = each.value.account_id
  kind       = "root"
  name       = "root"
  phase      = "http_request_firewall_custom"
  rules {
    action = "execute"
    action_parameters {
      id      = cloudflare_ruleset.Global-account-waf-ruleset[each.key].id
      //version = "latest"
    }
    description  = var.ruleset_description
    enabled      = true
    expression   = "(cf.zone.plan eq \"ENT\")"
  }
}


