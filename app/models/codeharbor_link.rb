# frozen_string_literal: true

class CodeharborLink < ApplicationRecord
  validates :push_url, presence: true
  validates :check_uuid_url, presence: true
  validates :api_key, presence: true

  belongs_to :user, foreign_key: :user_id, class_name: 'InternalUser'

  def to_s
    id.to_s
  end
end
