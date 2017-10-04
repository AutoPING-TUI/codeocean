require 'concurrent/future'

module SubmissionScoring
  def collect_test_results(submission)
    submission.collect_files.select(&:teacher_defined_test?).map do |file|
      future = Concurrent::Future.execute do
        assessor = Assessor.new(execution_environment: submission.execution_environment)
        output = execute_test_file(file, submission)
        assessment = assessor.assess(output)
        passed = ((assessment[:passed] == assessment[:count]) and (assessment[:score] > 0))
        testrun_output = passed ? nil : 'message: ' + output[:message].to_s + '\n stdout: ' + output[:stdout].to_s + '\n stderr: ' + output[:stderr].to_s
        Testrun.new(submission: submission, cause: 'assess', file: file, passed: passed, output: testrun_output).save
        output.merge!(assessment)
        output.merge!(filename: file.name_with_extension, message: feedback_message(file, output[:score]), weight: file.weight)
      end
      future.value
    end
  end
  private :collect_test_results

  def execute_test_file(file, submission)
    DockerClient.new(execution_environment: file.context.execution_environment, user: current_user).execute_test_command(submission, file.name_with_extension)
  end
  private :execute_test_file

  def feedback_message(file, score)
    set_locale
    score == Assessor::MAXIMUM_SCORE ? I18n.t('exercises.implement.default_feedback') : render_markdown(file.feedback_message)
  end

  def score_submission(submission)
    outputs = collect_test_results(submission)
    score = 0.0
    unless outputs.nil? || outputs.empty?
      outputs.each do |output|
        unless output.nil?
          score += output[:score] * output[:weight]
        end
      end
    end
    submission.update(score: score)
    outputs
  end
end
