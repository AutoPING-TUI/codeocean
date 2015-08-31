require 'concurrent/future'

module SubmissionScoring
  def collect_test_results(submission)
    submission.collect_files.select(&:teacher_defined_test?).map do |file|
      future = Concurrent::Future.execute do
        assessor = Assessor.new(execution_environment: submission.execution_environment)
        output = execute_test_file(file, submission)
        output.merge!(assessor.assess(output))
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
    score == Assessor::MAXIMUM_SCORE ? I18n.t('exercises.implement.default_feedback') : file.feedback_message
  end

  def score_submission(submission)
    outputs = collect_test_results(submission)
    score = 0.0
    if not (outputs.nil? || outputs.empty?)
      outputs.each do |output|
        if not output.nil?
          score += output[:score] * output[:weight]
        end
      end
    end
    submission.update(score: score)
    outputs
  end
end
