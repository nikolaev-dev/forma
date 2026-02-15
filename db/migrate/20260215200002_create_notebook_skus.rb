class CreateNotebookSkus < ActiveRecord::Migration[8.1]
  def change
    create_table :notebook_skus do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.integer :price_cents, null: false
      t.string :currency, null: false, default: "RUB"
      t.boolean :is_active, default: true
      t.jsonb :specs, default: {}
      t.jsonb :brand_elements, default: {}

      t.timestamps
    end

    add_index :notebook_skus, :code, unique: true
  end
end
