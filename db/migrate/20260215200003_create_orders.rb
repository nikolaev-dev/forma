class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.string :order_number, null: false
      t.references :user, foreign_key: true
      t.references :anonymous_identity, foreign_key: true
      t.string :status, null: false, default: "draft"
      t.integer :subtotal_cents, null: false, default: 0
      t.integer :shipping_cents, null: false, default: 0
      t.integer :total_cents, null: false, default: 0
      t.string :currency, null: false, default: "RUB"
      t.string :customer_name
      t.string :customer_phone
      t.column :customer_email, :citext
      t.string :shipping_method
      t.jsonb :shipping_address, default: {}
      t.string :tracking_number
      t.text :notes
      t.string :barcode_value, null: false
      t.string :barcode_type, null: false, default: "code128"
      t.text :production_notes

      t.timestamps
    end

    add_index :orders, :order_number, unique: true
    add_index :orders, :barcode_value, unique: true
    add_index :orders, :status
  end
end
