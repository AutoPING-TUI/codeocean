# frozen_string_literal: true

class Submission < ApplicationRecord
  include Context
  include Creation
  include ActionCableHelper

  CAUSES = %w[assess download file render run save submit test autosave requestComments remoteAssess
              remoteSubmit].freeze
  FILENAME_URL_PLACEHOLDER = '{filename}'
  MAX_COMMENTS_ON_RECOMMENDED_RFC = 5
  OLDEST_RFC_TO_SHOW = 6.months

  belongs_to :exercise
  belongs_to :study_group, optional: true

  has_many :testruns
  has_many :structured_errors
  has_many :comments, through: :files

  belongs_to :external_users, lambda {
                                where(submissions: {user_type: 'ExternalUser'}).includes(:submissions)
                              }, foreign_key: :user_id, class_name: 'ExternalUser', optional: true
  belongs_to :internal_users, lambda {
                                where(submissions: {user_type: 'InternalUser'}).includes(:submissions)
                              }, foreign_key: :user_id, class_name: 'InternalUser', optional: true

  delegate :execution_environment, to: :exercise

  scope :final, -> { where(cause: %w[submit remoteSubmit]) }
  scope :intermediate, -> { where.not(cause: 'submit') }

  scope :before_deadline, lambda {
                            joins(:exercise).where('submissions.updated_at <= exercises.submission_deadline OR exercises.submission_deadline IS NULL')
                          }
  scope :within_grace_period, lambda {
                                joins(:exercise).where('(submissions.updated_at > exercises.submission_deadline) AND (submissions.updated_at <= exercises.late_submission_deadline OR exercises.late_submission_deadline IS NULL)')
                              }
  scope :after_late_deadline, lambda {
                                joins(:exercise).where('submissions.updated_at > exercises.late_submission_deadline')
                              }

  scope :latest, -> { order(updated_at: :desc).first }

  scope :in_study_group_of, ->(user) { where(study_group_id: user.study_groups) unless user.admin? }

  validates :cause, inclusion: {in: CAUSES}
  validates :exercise_id, presence: true

  # after_save :trigger_working_times_action_cable

  def build_files_hash(files, attribute)
    files.map(&attribute.to_proc).zip(files).to_h
  end

  private :build_files_hash

  def collect_files
    ancestors = build_files_hash(exercise.files.includes(:file_type), :id)
    descendants = build_files_hash(files.includes(:file_type), :file_id)
    ancestors.merge(descendants).values
  end

  def main_file
    collect_files.detect(&:main_file?)
  end

  def file_by_name(file_path)
    # expects the full file path incl. file extension
    # Caution: There must be no unnecessary path prefix included.
    # Use `file.ext` rather than `./file.ext`
    collect_files.detect {|file| file.filepath == file_path }
  end

  def normalized_score
    ::NewRelic::Agent.add_custom_attributes({unnormalized_score: score})
    if !score.nil? && !exercise.maximum_score.nil? && exercise.maximum_score.positive?
      score / exercise.maximum_score
    else
      0
    end
  end

  def percentage
    (normalized_score * 100).round
  end

  def siblings
    user.submissions.where(exercise_id: exercise_id)
  end

  def to_s
    Submission.model_name.human
  end

  def before_deadline?
    if exercise.submission_deadline.present?
      updated_at <= exercise.submission_deadline
    else
      false
    end
  end

  def within_grace_period?
    if exercise.submission_deadline.present? && exercise.late_submission_deadline.present?
      updated_at > exercise.submission_deadline && updated_at <= exercise.late_submission_deadline
    else
      false
    end
  end

  def after_late_deadline?
    if exercise.late_submission_deadline.present?
      updated_at > exercise.late_submission_deadline
    elsif exercise.submission_deadline.present?
      updated_at > exercise.submission_deadline
    else
      false
    end
  end

  def redirect_to_feedback?
    # Redirect 10% of users to the exercise feedback page. Ensure, that always the same
    # users get redirected per exercise and different users for different exercises. If
    # desired, the number of feedbacks can be limited with exercise.needs_more_feedback?(submission)
    (user_id + exercise.created_at.to_i) % 10 == 1
  end

  def own_unsolved_rfc
    RequestForComment.unsolved.find_by(exercise_id: exercise, user_id: user_id)
  end

  def unsolved_rfc
    RequestForComment.unsolved.where(exercise_id: exercise).where.not(question: nil).where(created_at: OLDEST_RFC_TO_SHOW.ago..Time.current).order('RANDOM()').find do |rfc_element|
      ((rfc_element.comments_count < MAX_COMMENTS_ON_RECOMMENDED_RFC) && !rfc_element.question.empty?)
    end
  end

  def calculate_score
    file_scores = nil
    # If prepared_runner raises an error, no Testrun will be created.
    prepared_runner do |runner, waiting_duration|
      file_scores = collect_files.select(&:teacher_defined_assessment?).map do |file|
        score_command = command_for execution_environment.test_command, file.name_with_extension
        output = {file_role: file.role, waiting_for_container_time: waiting_duration}
        stdout = +''
        stderr = +''
        begin
          exit_code = 1 # default to error
          execution_time = runner.attach_to_execution(score_command) do |socket|
            socket.on :stderr do |data|
              stderr << data
            end
            socket.on :stdout do |data|
              stdout << data
            end
            socket.on :exit do |received_exit_code|
              exit_code = received_exit_code
            end
          end
          output.merge!(container_execution_time: execution_time, status: exit_code.zero? ? :ok : :failed)
        rescue Runner::Error::ExecutionTimeout => e
          Rails.logger.debug { "Running tests in #{file.name_with_extension} for submission #{id} timed out: #{e.message}" }
          output.merge!(status: :timeout, container_execution_time: e.execution_duration)
        rescue Runner::Error => e
          Rails.logger.debug { "Running tests in #{file.name_with_extension} for submission #{id} failed: #{e.message}" }
          output.merge!(status: :failed, container_execution_time: e.execution_duration)
        ensure
          output.merge!(stdout: stdout, stderr: stderr)
        end
        score_file(output, file)
      end
    end
    combine_file_scores(file_scores)
  end

  def run(file, &block)
    run_command = command_for execution_environment.run_command, file
    durations = {}
    prepared_runner do |runner, waiting_duration|
      durations[:execution_duration] = runner.attach_to_execution(run_command, &block)
      durations[:waiting_duration] = waiting_duration
    rescue Runner::Error => e
      e.waiting_duration = waiting_duration
      raise
    end
    durations
  end

  private

  def prepared_runner
    request_time = Time.zone.now
    begin
      runner = Runner.for(user, exercise)
      runner.copy_files(collect_files)
    rescue Runner::Error => e
      e.waiting_duration = Time.zone.now - request_time
      raise
    end
    waiting_duration = Time.zone.now - request_time
    yield(runner, waiting_duration)
  end

  def command_for(template, file)
    filepath = collect_files.find {|f| f.name_with_extension == file }.filepath
    template % command_substitutions(filepath)
  end

  def command_substitutions(filename)
    {
      class_name: File.basename(filename, File.extname(filename)).upcase_first,
      filename: filename,
      module_name: File.basename(filename, File.extname(filename)).underscore,
    }
  end

  def score_file(output, file)
    assessor = Assessor.new(execution_environment: execution_environment)
    assessment = assessor.assess(output)
    passed = ((assessment[:passed] == assessment[:count]) and (assessment[:score]).positive?)
    testrun_output = passed ? nil : "status: #{output[:status]}\n stdout: #{output[:stdout]}\n stderr: #{output[:stderr]}"
    if testrun_output.present?
      execution_environment.error_templates.each do |template|
        pattern = Regexp.new(template.signature).freeze
        StructuredError.create_from_template(template, testrun_output, self) if pattern.match(testrun_output)
      end
    end
    testrun = Testrun.create(
      submission: self,
      cause: 'assess', # Required to differ run and assess for RfC show
      file: file, # Test file that was executed
      passed: passed,
      output: testrun_output,
      container_execution_time: output[:container_execution_time],
      waiting_for_container_time: output[:waiting_for_container_time]
    )

    filename = file.name_with_extension

    if file.teacher_defined_linter?
      LinterCheckRun.create_from(testrun, assessment)
      assessment = assessor.translate_linter(assessment, I18n.locale)

      # replace file name with hint if linter is not used for grading. Refactor!
      filename = I18n.t('exercises.implement.not_graded') if file.weight.zero?
    end

    output.merge!(assessment)
    output.merge!(filename: filename, message: feedback_message(file, output), weight: file.weight)
  end

  def feedback_message(file, output)
    if output[:score] == Assessor::MAXIMUM_SCORE && output[:file_role] == 'teacher_defined_test'
      I18n.t('exercises.implement.default_test_feedback')
    elsif output[:score] == Assessor::MAXIMUM_SCORE && output[:file_role] == 'teacher_defined_linter'
      I18n.t('exercises.implement.default_linter_feedback')
    else
      # The render_markdown method from application_helper.rb is not available in model classes.
      ActionController::Base.helpers.sanitize(
        Kramdown::Document.new(file.feedback_message).to_html,
        tags: %w[strong],
        attributes: []
      )
    end
  end

  def combine_file_scores(outputs)
    score = 0.0
    if outputs.present?
      outputs.each do |output|
        score += output[:score] * output[:weight] unless output.nil?
      end
    end
    update(score: score)
    if normalized_score.to_d == 1.0.to_d
      Thread.new do
        RequestForComment.where(exercise_id: exercise_id, user_id: user_id, user_type: user_type).find_each do |rfc|
          rfc.full_score_reached = true
          rfc.save
        end
      ensure
        ActiveRecord::Base.connection_pool.release_connection
      end
    end
    if @embed_options.present? && @embed_options[:hide_test_results] && outputs.present?
      outputs.each do |output|
        output.except!(:error_messages, :count, :failed, :filename, :message, :passed, :stderr, :stdout)
      end
    end

    # Return all test results except for those of a linter if not allowed
    show_linter = Python20CourseWeek.show_linter? exercise
    outputs&.reject do |output|
      next if show_linter || output.blank?

      output[:file_role] == 'teacher_defined_linter'
    end
  end
end
