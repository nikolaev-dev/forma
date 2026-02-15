class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.string :payable_type, null: false
      t.bigint :payable_id, null: false
      t.string :provider, null: false, default: "yookassa"
      t.string :provider_payment_id
      t.string :status, null: false, default: "created"
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "RUB"
      t.string :idempotence_key
      t.text :confirmation_url
      t.datetime :captured_at
      t.jsonb :raw, default: {}

      t.timestamps
    end

    add_index :payments, [ :payable_type, :payable_id ]
    add_index :payments, :provider_payment_id, unique: true, where: "provider_payment_id IS NOT NULL"
    add_index :payments, :status
  end
end
