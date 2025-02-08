class ChatGptHistoryOnScore < ApplicationRecord
  validates :prompt, :response, presence: true
end
