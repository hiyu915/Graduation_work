class CreateCities < ActiveRecord::Migration[7.1]
  def change
    create_table :cities do |t|
      t.string :name, null: false
      t.references :prefecture, null: false, foreign_key: true

      t.timestamps
    end

    add_index :cities, [ :prefecture_id, :name ], unique: true
  end
end
