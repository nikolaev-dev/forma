class CreateGenerationPasses < ActiveRecord::Migration[8.0]
  def change
    create_table :generation_passes do |t|
      t.references :user, null: true, foreign_key: true
      t.string :status, null: false, default: "active"
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.integer :price_cents, null: false, default: 10000
      t.string :currency, default: "RUB"
      t.jsonb :fair_use, default: {}

      t.timestamps
    end

    add_index :generation_passes, [:user_id, :status]
  end
end
