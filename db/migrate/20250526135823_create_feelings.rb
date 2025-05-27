class CreateFeelings < ActiveRecord::Migration[7.1]
  def change
    create_table :feelings do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :feelings, :name, unique: true
  end
end
