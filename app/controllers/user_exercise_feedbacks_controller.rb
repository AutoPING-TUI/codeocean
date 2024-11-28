# frozen_string_literal: true

class UserExerciseFeedbacksController < ApplicationController
  include CommonBehavior

  before_action :set_exercise_and_authorize
  before_action :set_user_exercise_feedback, only: %i[edit update destroy]
  before_action :set_presets, only: %i[new edit create update]

  def comment_presets
    [[0, t('user_exercise_feedback.difficulty_easy')],
     [1, t('user_exercise_feedback.difficulty_some_what_easy')],
     [2, t('user_exercise_feedback.difficulty_ok')],
     [3, t('user_exercise_feedback.difficulty_some_what_difficult')],
     [4, t('user_exercise_feedback.difficult_too_difficult')]]
  end

  def error_presets
    [[0, t('user_exercise_feedback.very_good')],
     [1, t('user_exercise_feedback.good')],
     [2, t('user_exercise_feedback.neutral')],
     [3, t('user_exercise_feedback.bad')],
     [4, t('user_exercise_feedback.very_bad')]]
  end


  def new
    @uef = UserExerciseFeedback.find_or_initialize_by(user: current_user, exercise: @exercise)
    authorize!
  end

  def edit; end

  def create
    Sentry.set_extras(params: uef_params)

    rfc = RequestForComment.unsolved.where(exercise: @exercise, user: current_user).first
    submission = begin
      current_contributor.submissions.where(exercise: @exercise).order(created_at: :desc).first
    rescue StandardError
      nil
    end

    @uef = UserExerciseFeedback.find_or_initialize_by(user: current_user, exercise: @exercise)
    @uef.assign_attributes(uef_params)
    authorize!
    if validate_inputs(uef_params)
      path =
        if rfc && submission && submission.normalized_score.to_d == BigDecimal('1.0')
          request_for_comment_path(rfc)
        else
          implement_exercise_path(@exercise)
        end
      create_and_respond(object: @uef, path: proc { path })
    else
      flash.now[:danger] = t('shared.message_failure')
      redirect_back fallback_location: exercise_user_exercise_feedback_path(@uef)
    end
  end

  def update
    submission = begin
      @exercise.final_submission(current_contributor)
    rescue StandardError
      nil
    end
    rfc = RequestForComment.unsolved.where(exercise: @exercise, user: current_user).first
    authorize!
    if validate_inputs(uef_params)
      path =
        if rfc && submission && submission.normalized_score.to_d == BigDecimal('1.0')
          request_for_comment_path(rfc)
        else
          implement_exercise_path(@exercise)
        end
      update_and_respond(object: @uef, params: uef_params, path:)
    else
      flash.now[:danger] = t('shared.message_failure')
      redirect_back fallback_location: exercise_user_exercise_feedback_path(@uef)
    end
  end

  def destroy
    authorize!
    destroy_and_respond(object: @uef)
  end

  private

  def authorize!
    raise Pundit::NotAuthorizedError if @uef.present? && @uef.exercise != @exercise

    authorize(@uef)
  end

  def set_exercise_and_authorize
    @exercise = Exercise.find(params[:exercise_id])
    authorize(@exercise, :implement?)
  end

  def set_user_exercise_feedback
    @uef = UserExerciseFeedback.find(params[:id])
    authorize!
  end

  def set_presets
    @texts = comment_presets.to_a
    @errors = error_presets.to_a

  end

  def uef_params
    return if params[:user_exercise_feedback].blank?

    exercise_id = if params[:user_exercise_feedback].nil?
                    params[:exercise_id]
                  else
                    params[:user_exercise_feedback][:exercise_id]
                  end

    exercise = Exercise.find(exercise_id)
    authorize(exercise, :implement?)

    latest_submission = exercise.final_submission(current_contributor)
    authorize(latest_submission, :show?)

    params[:user_exercise_feedback]
      .permit(:feedback_text, :difficulty, :exercise_id, :user_estimated_worktime_minutes, :user_estimated_worktime_hours, :user_error_feedback, :user_error_feedback_text)
      .merge(user: current_user,
        submission: latest_submission,
        normalized_score: latest_submission&.normalized_score)
  end

  def validate_inputs(uef_params)
    if uef_params[:difficulty].to_i.negative? || uef_params[:difficulty].to_i >= comment_presets.size
      false
    else
      !(uef_params[:user_estimated_worktime_hours].to_i.negative? || uef_params[:user_estimated_worktime_minutes].to_i.negative? )
    end
  rescue StandardError
    false
  end
end
