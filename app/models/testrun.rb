# frozen_string_literal: true

class Testrun < ApplicationRecord
  include Creation
  belongs_to :file, class_name: 'CodeOcean::File', optional: true
  belongs_to :submission
  belongs_to :testrun_execution_environment, optional: true, dependent: :destroy
  has_many :testrun_messages, dependent: :destroy

  CONSOLE_OUTPUT = %w[stdout stderr].freeze
  CAUSES = %w[assess run].freeze

  enum :status, {
    ok: 0,
    failed: 1,
    container_depleted: 2,
    timeout: 3,
    out_of_memory: 4,
    terminated_by_client: 5,
    runner_in_use: 6,
  }, default: :ok, prefix: true

  validates :exit_code, numericality: {only_integer: true, min: 0, max: 255}, allow_nil: true
  validates :status, presence: true
  validates :cause, inclusion: {in: CAUSES}

  def log
    if testrun_messages.loaded?
      testrun_messages.filter {|m| m.cmd_write? && CONSOLE_OUTPUT.include?(m.stream) }.pluck(:log).join.presence
    else
      testrun_messages.output.pluck(:log).join.presence
    end
  end

  def generate_ai_feedback
    # Validate if the exercise allows automatic feedback
    unless submission.exercise.allow_ai_feedback_on_score
      raise 'Automatic feedback is not enabled for this exercise.'
    end

    chatgpt_request = ChatGptService::ChatGptRequest.new

    prompt = ChatGptHelper.format_prompt(
      learner_solution: submission.main_file.content,
      exercise: submission.exercise.description,
      test_results: output,
    )

    feedback_message = chatgpt_request.make_chat_gpt_request(prompt, false)

    # Format and sanitize the feedback message
    formatted_feedback = Kramdown::Document.new(feedback_message).to_html
    sanitized_feedback = ActionController::Base.helpers.sanitize(
      formatted_feedback,
      tags: %w(p br strong em a code pre h1 h2 h3 ul ol li blockquote),
      attributes: %w(href)
    )

    sanitized_feedback.html_safe
  rescue => e
    # Return the error message to be handled by the caller
    e.message
  end

end
