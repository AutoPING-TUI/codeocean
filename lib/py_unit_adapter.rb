# frozen_string_literal: true

class PyUnitAdapter < TestingFrameworkAdapter
  COUNT_REGEXP = /Ran (\d+) test/
  FAILURES_REGEXP = /FAILED \(.*failures=(\d+).*\)/
  ERRORS_REGEXP = /FAILED \(.*errors=(\d+).*\)/
  ASSERTION_ERROR_REGEXP = /^(ERROR|FAIL):\ (.*?)\ .*?^[^.\n]*?(Error|Exception):\s((\s|\S)*?)(>>>[^>]*?)*\s\s(-|=){70}/m
  #regex to catch bad errors hindering code execution
  BAD_ERROR_REGEXP = /File\s\"(.*)\"(?:.*)line\s(\d+)\s*(?:.*)\s*(?:\^*)\s*(SyntaxError|IndentationError|TabError):(.*)/

  def self.framework_name
    'PyUnit'
  end

  def parse_output(output)
    # PyUnit is expected to print test results on Stderr!
    count = output[:stderr].scan(COUNT_REGEXP).try(:last).try(:first).try(:to_i) || 0
    failed = output[:stderr].scan(FAILURES_REGEXP).try(:last).try(:first).try(:to_i) || 0
    errors = output[:stderr].scan(ERRORS_REGEXP).try(:last).try(:first).try(:to_i) || 0
    begin
      assertion_error_matches = Timeout.timeout(2.seconds) do
        output[:stderr].scan(ASSERTION_ERROR_REGEXP).map do |match|
          testname = match[1]
          error = match[3].strip

          if testname == 'test_assess'
            error
          else
            "#{testname}: #{error}"
          end
        end || []
      end
    rescue Timeout::Error
      Sentry.capture_message({stderr: output[:stderr], regex: ASSERTION_ERROR_REGEXP}.to_json)
      assertion_error_matches = []
    end

    total_failed = failed + errors

    if count < total_failed
      # Catch a weird edge case where the test count is less than the failed count.
      # This might happen in PyUnit, when a test is failing (by design) during the setUpClass phase.
      # In those cases, we might get the following output: Ran 0 tests in 0.001s, FAILED (failures=1)
      # Normally, we would calculate the passed tests as count (0) - failed (1) = passed (-1).
      # In the given scenario, a negative number of passed tests doesn't make sense.
      # Hence, we assume that the count is invalid and increase it by the number of failed tests.
      count += total_failed
    end
    
    #catch bad errors here
    begin
      bad_error_matches = Timeout.timeout(2.seconds) do
        output[:stderr].scan(BAD_ERROR_REGEXP).map do |match|
          file_name=match[0]
          line_number=match[1]
          error_name=match[2]
          error_message=match[3].strip
          #error message, uses markdown and in-line html in markdown
          "<span style=\"color:red\">**#{error_name}**</span>: #{error_message} in **file** #{file_name} **line #{line_number}**"
        end || []
      end
    rescue Timeout::Error
      Sentry.capture_message({stderr: output[:stderr], regex: BAD_ERROR_REGEXP}.to_json)
      bad_error_matches = []
    end
    #add bad errors to normal error array
    {count:, failed: failed + errors, error_messages: assertion_error_matches.flatten.compact_blank+bad_error_matches}
  end
end
