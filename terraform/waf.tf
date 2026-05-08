# terraform/waf.tf

# 1. Maga a Tűzfal (Web ACL)
resource "aws_wafv2_web_acl" "main" {
  name        = "serverless-waf"
  scope       = "REGIONAL" # Mivel ALB elé tesszük, REGIONAL kell (nem CloudFront)
  description = "SQL injection védelem a Fargate apphoz"

  default_action {
    allow {} # Alapértelmezésben mindent átengedünk...
  }

  # ...kivéve azokat, amik fennakadnak ezen a szabályon:
  rule {
    name     = "SQLInjectionRule"
    priority = 1
    action {
      block {} # Blokkoljuk a gyanús kéréseket
    }
    statement {
      sqli_match_statement {
        text_transformation {
          priority = 1
          type     = "URL_DECODE"
        }
        text_transformation {
          priority = 2
          type     = "HTML_ENTITY_DECODE"
        }
        field_to_match {
          body {} # Ellenőrizzük a POST kérések törzsét
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLInjectionRuleMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "ServerlessWafMetric"
    sampled_requests_enabled   = true
  }
}

# 2. Összekötjük a WAF-ot az ALB-vel
resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = aws_lb.main.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}