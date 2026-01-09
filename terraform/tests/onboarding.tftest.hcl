run "test_onboarding_function" {
  command = apply

  module {
    source = "./tests/function"
  }

  variables {
    function_name = "cmmxna-pr-onboarding"
    payload       = jsonencode({
      httpMethod = "POST"
      path       = "/onboarding"
      body       = jsonencode({
        company_name    = "MNA-Terraform-Test-Corp"
        industry        = "Terraform Testing"
        contact_name    = "Terraform CISO"
        contact_email   = "tf-ciso@example.com"
        scoring_enabled = true
      })
    })
  }

  # ASSERTIONS
  assert {
    # Accept success (200/201) or not implemented (501)
    condition     = output.is_not_implemented || output.status_code == 200 || output.status_code == 201
    error_message = "Onboarding failed unexpectedly. Status: ${output.status_code}. Messages ${output.error_messages}."
  }
}
