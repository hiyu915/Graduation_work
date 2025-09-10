class ChangeShopIdToNullableInPosts < ActiveRecord::Migration[7.0]
  def change
    change_column_null :posts, :shop_id, true
  end
end