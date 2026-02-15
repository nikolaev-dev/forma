class CreateDesignRatings < ActiveRecord::Migration[8.0]
  def change
    create_table :design_ratings do |t|
      t.references :design, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.string :source, null: false, default: "user"
      t.integer :score, null: false
      t.string :comment

      t.timestamps
    end

    add_index :design_ratings, [:design_id, :user_id], unique: true, where: "source = 'user'", name: "idx_design_ratings_user_unique"
  end
end
