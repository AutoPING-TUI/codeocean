class ChatGptHistoryOnRfc < ApplicationRecord
  validates :prompt, :response, presence: true
end
