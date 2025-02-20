# app/jobs/generate_automatic_comments_job.rb
class GenerateAutomaticCommentsJob < ApplicationJob

  queue_as :default
  def perform(request_for_comment, current_user)
    chat_gpt_user = InternalUser.find_by(email: 'chatgpt@example.org')
    chat_gpt_service = ChatGptService::ChatGptRequest.new
    request_for_comment.submission.files.each do |file|
      response_data = perform_request(request_for_comment, file, chat_gpt_service)
      next unless response_data.present?

      create_general_comment(
        response_data,
        file,
        chat_gpt_user,
        request_for_comment,
        current_user
      )

      # Create comments for each line-specific comment
      create_line_comments(response_data, file, chat_gpt_user)
    end
  end

  private
  
  def perform_request(request_for_comment, file, chat_gpt_service)
    prompt = ChatGptHelper.format_prompt(
      learner_solution: file.content,
      exercise: request_for_comment.submission.exercise.description,
      test_results: Testrun.where(submission_id: request_for_comment.submission.id).map(&:log).join("\n"),
      question: request_for_comment.question
    )
    response = chat_gpt_service.execute(prompt, true)
    ChatGptHistoryOnRfc.create!(
      rfc_id: request_for_comment.id,
      prompt: prompt,
      response: response
    )
    ChatGptHelper.format_response(response)
  end
  
  def create_general_comment(response_data, file, chat_gpt_user, request_for_comment, current_user)
    if response_data[:requirements_comments].present?
      comment = create_comment(
        text: response_data[:requirements_comments],
        file_id: file.id,
        row: '0',
        column: '0',
        user: chat_gpt_user
      )
    end
    send_emails(comment, request_for_comment, current_user, chat_gpt_user) if comment.persisted?
  end
  
  def create_line_comments(response_data, file, chat_gpt_user)
    response_data[:line_specific_comments].each do |line_comment|
      create_comment(
        text: line_comment[:comment],
        file_id: file.id,
        row: (line_comment[:line_number].positive? ? line_comment[:line_number] - 1 : line_comment[:line_number]).to_s,
        column: '0',
        user: chat_gpt_user
      )
    end
  end

  def create_comment(attributes)
    chat_gpt_disclaimer = I18n.t('exercises.editor.chat_gpt_disclaimer')
    Comment.create(
      text: "#{attributes[:text]}\n\n#{chat_gpt_disclaimer}",
      file_id: attributes[:file_id],
      row: attributes[:row],
      column: attributes[:column],
      user: attributes[:user]
    )
  end

  def send_emails(comment, request_for_comment, current_user, chat_gpt_user)
    send_mail_to_author(comment, request_for_comment, chat_gpt_user)
    send_mail_to_subscribers(comment, request_for_comment, current_user)

  end

  def send_mail_to_author(comment, request_for_comment, chat_gpt_user)
    if chat_gpt_user == comment.user
      UserMailer.got_new_comment(comment, request_for_comment, chat_gpt_user).deliver_later
    end
  end

  def send_mail_to_subscribers(comment, request_for_comment, current_user)
    request_for_comment.commenters.each do |commenter|
      subscriptions = Subscription.where(
        request_for_comment_id: request_for_comment.id,
        user: commenter,
        deleted: false
      )
      subscriptions.each do |subscription|
        next if subscription.user == current_user

        should_send = (subscription.subscription_type == 'author' && current_user == request_for_comment.user) ||
          (subscription.subscription_type == 'all')

        if should_send
          UserMailer.got_new_comment_for_subscription(comment, subscription, current_user).deliver_later
          break
        end
      end
    end
  end
end
