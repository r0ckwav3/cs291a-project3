class SetDefaultRatingToZero < ActiveRecord::Migration[8.1]
  def change
    change_column_default :expert_assignments, :rating, 0
  end
end
