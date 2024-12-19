# Terraform: Cloudflare Global WAF Ruleset with Account Overrides

This Terraform example applies a baseline WAF ruleset across multiple Cloudflare accounts while allowing for per-account overrides.

## Usage

1. **Prerequisites:**
   - Cloudflare Enterprise Advanced Security Bundle in order to have access to Account level WAF rules.
   - Install Terraform and the Cloudflare Terraform Provider.
   - Obtain your Cloudflare API token.
        -   This example makes use of HCP and the Cloudflare API is defined as an environment variable CLOUDFLARE_API_TOKEN
        -   If you wish to run this project locally remove the backend.tf file and set the cloudflare API token locally
   - Modify the `accounts.tf` file to define your accounts and their override rules.
   - Modify the `Global-WAF-custom-rules.tf`  file to define your rules

2. **Configuration:**

   - **`accounts.tf`:**
     ```terraform
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
     ```
   - **`Global-WAF-custom-rules.tf`:**
     ```terraform
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
                enabled = false
            }
            }
        ]
        }
     ```

3. **Run Terraform:**
   - `terraform init`
   - `terraform plan`
   - `terraform apply`

## How it Works

- A baseline set of rules is defined in the `Global-WAF-custom-rules.tf`.
- Account-specific overrides are applied using the `override_rules` attribute within each account's configuration in `accounts.tf`.
- `Global-WAF-custom.tf` merges the rules from `Global-WAF-custom-rules.tf` and each account override_rules, creates a ruleset and the ruleset entrypoint in each account.

## Note:

- This is a basic example and can be further customized based on your specific requirements.
- Ensure that you have the necessary permissions for the Cloudflare API to create and manage rulesets. 	`Account.Account Rulesets: write`
- Carefully review and test your configurations before applying them to production environments.