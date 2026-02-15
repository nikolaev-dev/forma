class CreateGenerationSelections < ActiveRecord::Migration[8.1]
  def change
    create_table :generation_selections do |t|
      t.references :generation, null: false, foreign_key: true
      t.references :generation_variant, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.references :anonymous_identity, foreign_key: true

      t.datetime :created_at, null: false
    end
  end
end
