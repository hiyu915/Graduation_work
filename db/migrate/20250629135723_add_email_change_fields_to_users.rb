class AddEmailChangeFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :unconfirmed_email, :string
    add_column :users, :email_change_token, :string
    add_column :users, :email_change_token_expires_at, :datetime
  end
end
