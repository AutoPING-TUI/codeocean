class UserMailer < ActionMailer::Base
  def activation_needed_email(user)
    @activation_url = activate_internal_user_url(user, token: user.activation_token)
    mail(subject: t('mailers.user_mailer.activation_needed.subject'), to: user.email)
  end

  def activation_success_email(*)
  end

  def reset_password_email(user)
    @reset_password_url = reset_password_internal_user_url(user, token: user.reset_password_token)
    mail(subject: t('mailers.user_mailer.reset_password.subject'), to: user.email)
  end

  def got_new_comment(comment, user, commenting_user)
    @commenting_user = commenting_user
    mail(subject: t('mailers.user_mailer.got_new_comment.subject'), to: user.email)
  end
end
