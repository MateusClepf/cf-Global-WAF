# Baseline ruleset applied to all accounts
locals {
  baseline_ruleset_ratelimit = [
    {
      ref         = "rate_limit_api_ip"
      description = "Rate limit API requests by IP"
      expression  = "http.request.uri.path contains \"/api/\""
      action      = "block"
      ratelimit = {
        #for characteristics "cf.colo.id" is a mandatory field as our RL rules are colo based.
        #More details on available parameters:
        #https://developers.cloudflare.com/waf/rate-limiting-rules/parameters/#with-the-same-characteristics
        characteristics     = ["cf.colo.id", "ip.src"]
        period              = 60
        requests_per_period = 100
        mitigation_timeout  = 600
      }
    },
    {
      ref         = "rate_limit_example_com_status_404"
      description = "Rate limit requests to www.example.com when exceeding the threshold of 404 responses on /status/"
      expression  = "http.host eq \"www.example.com\" and (http.request.uri.path matches \"^/status/\")"
      action      = "block"
      action_parameters = {
        response = {
          status_code  = 429
          content      = "{\"response\": \"block\"}"
          content_type = "application/json"
        }
      }
      ratelimit = {
        characteristics     = ["ip.src", "cf.colo.id"]
        period              = 10
        requests_per_period = 5
        mitigation_timeout  = 30
        counting_expression = "(http.host eq \"www.example.com\") and (http.request.uri.path matches \"^/status/\") and (http.response.code eq 404)"
      }
    }
  ]
}
