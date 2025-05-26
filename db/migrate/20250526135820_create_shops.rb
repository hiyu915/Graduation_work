class CreateShops < ActiveRecord::Migration[7.1]
  def change
    create_table :shops do |t|
      t.string :name, null: false
      t.references :location, null: false, foreign_key: true
      #t.float :latitude
      #t.float :longitude

      t.timestamps
    end
  end
end