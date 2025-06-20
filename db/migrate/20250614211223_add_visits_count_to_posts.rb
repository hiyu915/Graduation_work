class AddVisitsCountToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :visits_count, :integer
  end
end
