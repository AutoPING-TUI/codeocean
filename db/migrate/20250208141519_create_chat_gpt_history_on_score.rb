# frozen_string_literal: true

class CreateChatGptHistoryOnScore < ActiveRecord::Migration[7.2]
  def change
    create_table :chat_gpt_history_on_scores, id: :uuid do |t|
      t.integer :testrun_id
      t.text :prompt
      t.text :response

      t.timestamps
    end
  end
end
