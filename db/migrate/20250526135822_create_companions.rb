class CreateCompanions < ActiveRecord::Migration[7.1]
  def change
    create_table :companions do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :companions, :name, unique: true
  end
end
