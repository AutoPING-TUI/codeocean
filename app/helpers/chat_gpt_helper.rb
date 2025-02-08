
module ChatGptHelper


  def self.construct_prompt_for_rfc(request_for_comment, file)
    submission = request_for_comment.submission
    test_run_results = Testrun.where(submission_id: submission.id).map(&:log).join("\n")
    options = {
      learner_solution: file.content,
      exercise: submission.exercise.description,
      test_results: test_run_results,
      question: request_for_comment.question
    }
    format_prompt(options)
  end

  def self. format_prompt(options)
    if I18n.locale == :en
      file_path = Rails.root.join('app', 'services/chat_gpt_service/chat_gpt_prompts', 'prompt_en.xml')
      prompt = File.read(file_path)
      prompt.gsub!("[Learner's Code]", options[:learner_solution] || "")
      prompt.gsub!("[Task]", options[:exercise] || "")
      prompt.gsub!("[Error Message]", options[:test_results] || "")
      prompt.gsub!("[Student Question]", options[:question] || "")
    else
      file_path = Rails.root.join('app', 'services/chat_gpt_service/chat_gpt_prompts', 'prompt_de.xml')
      prompt = File.read(file_path)
      prompt.gsub!("[Code des Lernenden]", options[:learner_solution] || "")
      prompt.gsub!("[Aufgabenstellung]", options[:exercise] || "")
      prompt.gsub!("[Fehlermeldung]", options[:test_results] || "")
      prompt.gsub!("[Frage des Studierenden]", options[:question] || "")
    end

    prompt
  end

  def self.format_response(response)
    parsed_response = JSON.parse(response)
    requirements_comments = ''
    if parsed_response['requirements']
      requirements_comments = parsed_response['requirements'].map { |req| req['comment'] }.join("\n")
    end

    line_specific_comments = []
    if parsed_response['line_specific_comments']
      line_specific_comments = parsed_response['line_specific_comments'].map do |line_comment|
        {
          line_number: line_comment['line_number'],
          comment: line_comment['comment']
        }
      end
    end

    {
      requirements_comments: requirements_comments,
      line_specific_comments: line_specific_comments
    }
  end

end