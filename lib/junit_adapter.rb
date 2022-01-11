# frozen_string_literal: true

class JunitAdapter < TestingFrameworkAdapter
  COUNT_REGEXP = /Tests run: (\d+)/.freeze
  FAILURES_REGEXP = /Failures: (\d+)/.freeze
  SUCCESS_REGEXP = /OK \((\d+) tests?\)\s*(?:\x1B\]0;|exit)?\s*\z/.freeze
  ASSERTION_ERROR_REGEXP = /java\.lang\.AssertionError:?\s(.*?)\tat org.junit|org\.junit\.ComparisonFailure:\s(.*?)\tat org.junit/m.freeze

  def self.framework_name
    'JUnit 4'
  end

  def parse_output(output)
    if SUCCESS_REGEXP.match(output[:stdout])
      {count: Regexp.last_match(1).to_i, passed: Regexp.last_match(1).to_i}
    else
      count = output[:stdout].scan(COUNT_REGEXP).try(:last).try(:first).try(:to_i) || 0
      failed = output[:stdout].scan(FAILURES_REGEXP).try(:last).try(:first).try(:to_i) || 0
      error_matches = output[:stdout].scan(ASSERTION_ERROR_REGEXP) || []
      {count: count, failed: failed, error_messages: error_matches.flatten.compact_blank}
    end
  end
end
