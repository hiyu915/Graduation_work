class AddCountToVisits < ActiveRecord::Migration[7.1]
  def change
    add_column :visits, :count, :integer
  end
end
