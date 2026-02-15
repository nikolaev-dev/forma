class CreateOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :design, null: false, foreign_key: true
      t.references :notebook_sku, null: false, foreign_key: true
      t.references :filling, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.integer :unit_price_cents, null: false
      t.integer :total_price_cents, null: false
      t.string :format
      t.jsonb :settings_snapshot, default: {}

      t.timestamps
    end
  end
end
