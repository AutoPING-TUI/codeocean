class AddHelpToExecutionEnvironments < ActiveRecord::Migration[4.2]
  def change
    add_column :execution_environments, :help, :text
  end
end
