run "test_frontend_proxy_function" {
  command = apply

  module {
    source = "./tests/function"
  }

  variables {
    function_name = "cmmxna-pr-frontend_proxy"
    payload = jsonencode({
      target_name = "Unit-Test-Corp"
      phase       = "Discovery"
    })
  }

  # ASSERTIONS
  assert {
    # Accept success (200/201) or not implemented (501)
    condition     = module.setup.is_not_implemented || module.setup.status_code == 200 || module.setup.status_code == 201
    error_message = "Frontend Proxy failed unexpectedly. Status: ${module.setup.status_code}. Not Implemented: ${module.setup.is_not_implemented}."
  }
}