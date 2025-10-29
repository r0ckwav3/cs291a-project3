class RenameExpertIdToUserIdInExpertAssignments < ActiveRecord::Migration[8.1]
  def change
    rename_column :expert_assignments, :expert_id, :user_id
  end
end
