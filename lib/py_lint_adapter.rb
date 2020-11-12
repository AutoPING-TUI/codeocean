class PyLintAdapter < TestingFrameworkAdapter
  REGEXP = /Your code has been rated at (-?\d+\.?\d*)\/(\d+\.?\d*)/
  ASSERTION_ERROR_REGEXP = /^(.*?\.py):(\d+):(.*?)\(([^,]*?), ([^,]*?),([^,]*?)\) (.*?)$/

  def self.framework_name
    'PyLint'
  end

  def parse_output(output)
    regex_match = REGEXP.match(output[:stdout])
    if regex_match.blank?
      count = 0
      failed = 0
    else
      captures = regex_match.captures.map(&:to_f)
      count = captures.second
      passed = captures.first >= 0 ? captures.first : 0
      failed = count - passed
    end

    begin
      assertion_error_matches = Timeout.timeout(2.seconds) do
        output[:stdout].scan(ASSERTION_ERROR_REGEXP).map do |match|
          {
            file_name: match[0].strip,
            line: match[1].to_i,
            severity: match[2].strip,
            code: match[3].strip,
            name: match[4].strip,
            # e.g. function name, nil if outside of a function. Not always available
            scope: match[5].strip.presence,
            result: match[6].strip
          }
        end || []
      end
    rescue Timeout::Error
      assertion_error_matches = []
    end
    concatenated_errors = assertion_error_matches.map { |result| "#{result[:name]}: #{result[:result]}" }.flatten
    {count: count, failed: failed, error_messages: concatenated_errors, detailed_linter_results: assertion_error_matches}
  end

  def self.translate_linter(assessment)
    # The message will be translated once the results were stored in the database
    # See SubmissionScoring for actual function call

    return assessment unless assessment[:detailed_linter_results].present?

    assessment[:detailed_linter_results].map! do |message|
      severity = message[:severity]
      name = message[:name]

      message[:severity] = get_t("linter.#{severity}.severity_name", message[:severity])
      message[:name] = get_t("linter.#{severity}.#{name}.name", message[:name])

      regex = get_t("linter.#{severity}.#{name}.regex", nil)&.strip

      if regex.present?
        captures = message[:result].match(Regexp.new(regex)).named_captures.symbolize_keys

        replacement = captures.each do |key, value|
          value&.replace get_t("linter.#{severity}.#{name}.#{key}.#{value}", value)
        end
      else
        replacement = {}
      end

      replacement.merge!(locale: :de, default: message[:result])
      message[:result] = I18n.t("linter.#{severity}.#{name}.replacement", replacement)
      message
    end

    assessment[:error_messages] = assessment[:detailed_linter_results].map do |message|
      "#{message[:name]}: #{message[:result]}"
    end

    assessment
  rescue StandardError => e
    # A key was not defined or something really bad happened
    Raven.extra_context(assessment)
    Raven.capture_exception(e)
    assessment
  end

  def self.get_t(key, default)
    translation = I18n.t(key, locale: :de, default: default)
    Raven.capture_message({key: key, default: default}.to_json) if translation == default
    translation
  end
end
