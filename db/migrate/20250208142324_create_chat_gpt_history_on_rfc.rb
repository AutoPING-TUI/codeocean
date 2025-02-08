# frozen_string_literal: true

class CreateChatGptHistoryOnRfc < ActiveRecord::Migration[7.2]
  def change
    create_table :chat_gpt_history_on_rfcs, id: :uuid do |t|
      t.integer :rfc_id
      t.text :prompt
      t.text :response

      t.timestamps
    end
  end
end
