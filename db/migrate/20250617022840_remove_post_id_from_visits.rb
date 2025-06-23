class RemovePostIdFromVisits < ActiveRecord::Migration[7.1]
  def change
    remove_reference :visits, :post, foreign_key: true
  end
end
