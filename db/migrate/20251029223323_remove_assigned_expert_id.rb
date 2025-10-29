class RemoveAssignedExpertId < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :conversations, column: :assigned_expert_id
    remove_column :conversations, :assigned_expert_id, :bigint
  end
end
