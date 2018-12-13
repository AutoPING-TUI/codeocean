class ApplicationController < ActionController::Base
  include ApplicationHelper
  include Pundit

  MEMBER_ACTIONS = [:destroy, :edit, :show, :update]

  after_action :verify_authorized, except: [:help, :welcome]
  before_action :set_locale, :allow_iframe_requests, :load_embed_options
  protect_from_forgery(with: :exception, prepend: true)
  rescue_from Pundit::NotAuthorizedError, with: :render_not_authorized

  def current_user
    ::NewRelic::Agent.add_custom_attributes({ external_user_id: session[:external_user_id], session_user_id: session[:user_id] })
    @current_user ||= ExternalUser.find_by(id: session[:external_user_id]) || login_from_session || login_from_other_sources
  end

  def require_user!
    raise Pundit::NotAuthorizedError unless current_user
  end

  def render_not_authorized
    respond_to do |format|
      format.html { redirect_to(request.referrer || :root, alert: t('application.not_authorized')) }
      format.json { render json: {error: t('application.not_authorized')}, status: :unauthorized }
    end
  end
  private :render_not_authorized

  def set_locale
    session[:locale] = params[:custom_locale] || params[:locale] || session[:locale]
    I18n.locale = session[:locale] || I18n.default_locale
  end
  private :set_locale

  def welcome
  end

  def allow_iframe_requests
    response.headers.delete('X-Frame-Options')
  end

  def load_embed_options
    if session[:embed_options].present? && session[:embed_options].is_a?(Hash)
      @embed_options = session[:embed_options].symbolize_keys
    else
      @embed_options = {}
    end
    @embed_options
  end
  private :load_embed_options
end
