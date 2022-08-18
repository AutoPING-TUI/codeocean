# frozen_string_literal: true

class ConsumersController < ApplicationController
  include CommonBehavior

  before_action :set_consumer, only: MEMBER_ACTIONS

  def authorize!
    authorize(@consumer || @consumers)
  end
  private :authorize!

  def create
    @consumer = Consumer.new(consumer_params)
    authorize!
    create_and_respond(object: @consumer)
  end

  def destroy
    destroy_and_respond(object: @consumer)
  end

  def edit; end

  def consumer_params
    params[:consumer].permit(:name, :oauth_key, :oauth_secret) if params[:consumer].present?
  end
  private :consumer_params

  def index
    @consumers = Consumer.paginate(page: params[:page], per_page: per_page_param)
    authorize!
  end

  def new
    @consumer = Consumer.new(oauth_key: SecureRandom.hex, oauth_secret: SecureRandom.hex)
    authorize!
  end

  def set_consumer
    @consumer = Consumer.find_by(id: params[:id])
    authorize!
  end
  private :set_consumer

  def show; end

  def update
    update_and_respond(object: @consumer, params: consumer_params)
  end
end
