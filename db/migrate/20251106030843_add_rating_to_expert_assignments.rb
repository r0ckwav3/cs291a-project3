class AddRatingToExpertAssignments < ActiveRecord::Migration[8.1]
  def change
    add_column :expert_assignments, :rating, :integer
  end
end
