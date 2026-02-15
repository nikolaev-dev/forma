class CreateFavorites < ActiveRecord::Migration[8.0]
  def change
    create_table :favorites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :design, null: false, foreign_key: true

      t.datetime :created_at, null: false
    end

    add_index :favorites, [ :user_id, :design_id ], unique: true
  end
end
