# frozen_string_literal: true

class JunitAdapter < TestingFrameworkAdapter
  COUNT_REGEXP = /Tests run: (\d+)/
  FAILURES_REGEXP = /Failures: (\d+)/
  SUCCESS_REGEXP = /OK \((\d+) tests?\)\s*(?:\x1B\]0;|exit)?\s*\z/
  ASSERTION_ERROR_REGEXP = /java\.lang\.AssertionError:?\s(.*?)\tat org\.junit|org\.junit\.ComparisonFailure:\s(.*?)\tat org\.junit|\)\n(.*?)\tat org\.junit\.internal\.ComparisonCriteria\.arrayEquals\(ComparisonCriteria\.java:\d*\).*(?=\n\tat org\.junit\.internal)/m
  COMPILE_ERROR_REGEXP_1LINE = /(.*).java:(\d*):\serror:\s(unclosed string literal|illegal start of expression|not a statement|unexpected type|(?:.+)expected|bad operand types (?:.*)|variable (?:.*) might not have been initialized|incompatible types:(?:.*)|missing return (?:.*)|invalid method declaration(?:.*)|unreachable statement|(?:.*) cannot be referenced from a static context|reached end of file while parsing)\s*^\s*(.*)/
  COMPILE_ERROR_REGEXP_3LINE = /(.*).java:(\d*):\serror:\s((?:.*) cannot be applied to (?:.*)|cannot find symbol)\s*^\s*(.*)\s*(?:\^*)\s*(.*)\s*(.*)/
  
  def self.framework_name
    'JUnit 4'
  end

  def parse_output(output)
    if SUCCESS_REGEXP.match(output[:stdout])
      {count: Regexp.last_match(1).to_i, passed: Regexp.last_match(1).to_i}
    else
      count = output[:stdout].scan(COUNT_REGEXP).try(:last).try(:first).try(:to_i) || 0
      failed = output[:stdout].scan(FAILURES_REGEXP).try(:last).try(:first).try(:to_i) || 0
      error_matches = output[:stdout].scan(ASSERTION_ERROR_REGEXP)
      compile_error_matches_1line = output[:stderr].scan(COMPILE_ERROR_REGEXP_1LINE).map do |match|
        error_file=match[0]
        line_number=match[1]
        error_name=match[2].strip
        code=match[3].strip
        if error_file.downcase().include? "test"

        else
          "<span style=\"color:red\">**Compilation Error**</span> in **file** #{error_file} **line #{line_number}** occured **#{error_name}** at #{code} "
        end
      end || []
      compile_error_matches_3line = output[:stderr].scan(COMPILE_ERROR_REGEXP_3LINE).map do |match|
        error_file=match[0]
        line_number=match[1]
        error_name=match[2].strip
        code_line_1=match[3].strip
        code_line_2=match[4]
        code_line_3=match[5]
        if error_file.downcase().include? "test"

        else
          "<span style=\"color:red\">**Compilation Error**</span> in **file** #{error_file} **line #{line_number}** occured **#{error_name}** at #{code_line_1}\n #{code_line_2}\n #{code_line_3} "
        end
      end || []
      {count:, failed:, error_messages: error_matches.flatten.compact_blank+compile_error_matches_1line+compile_error_matches_3line}
    end
  end
end
