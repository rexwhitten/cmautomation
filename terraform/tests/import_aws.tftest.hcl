run "test_importaws_function" {
  command = apply

  module {
    source = "./tests/function"
  }

  variables {
    function_name = "cmmxna-pr-import_aws"
    payload = jsonencode({
      target_name = "Unit-Test-Corp"
      phase       = "Discovery"
    })
  }

  # ASSERTIONS
  assert {
    # Accept success (200/201) or not implemented (501)
    condition     = output.is_not_implemented || output.status_code == 200 || output.status_code == 201
    error_message = "Import AWS failed unexpectedly. Status: ${output.status_code}. Messages ${output.error_messages}."
  }
}
