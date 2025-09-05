class RemoveProviderUidFromUsers < ActiveRecord::Migration[7.1]
  def change
    remove_index :users, column: [:provider, :uid] if index_exists?(:users, [:provider, :uid])
    remove_column :users, :provider, :string if column_exists?(:users, :provider)
    remove_column :users, :uid, :string     if column_exists?(:users, :uid)
  end
end
