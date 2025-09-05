class CreateAuthentications < ActiveRecord::Migration[7.1]
  def change
    create_table :authentications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false
      t.timestamps
    end
    add_index :authentications, [:provider, :uid], unique: true

    if column_exists?(:users, :provider) && column_exists?(:users, :uid)
      reversible do |dir|
        dir.up do
          execute <<~SQL
            INSERT INTO authentications (user_id, provider, uid, created_at, updated_at)
            SELECT id, provider, uid, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
            FROM users
            WHERE provider IS NOT NULL AND uid IS NOT NULL
          SQL
        end
      end
    end
  end
end