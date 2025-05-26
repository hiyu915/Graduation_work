class CreatePosts < ActiveRecord::Migration[7.1]
  def change
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      #t.references :category, null: false, foreign_key: true
      #t.references :shop, null: false, foreign_key: true
      #t.references :companion, null: false, foreign_key: true
      #t.references :feeling, null: false, foreign_key: true
     #t.references :visit_reason, null: false, foreign_key: true
      t.text :body

      t.timestamps
    end
  end
end
