# frozen_string_literal: true

class AddFileIdToExercises < ActiveRecord::Migration[4.2]
  def change
    add_reference :exercises, :file
  end
end
