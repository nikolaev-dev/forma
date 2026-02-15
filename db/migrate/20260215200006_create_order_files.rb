class CreateOrderFiles < ActiveRecord::Migration[8.1]
  def change
    create_table :order_files do |t|
      t.references :order, null: false, foreign_key: true
      t.string :file_type, null: false
      t.string :status, default: "created"
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :order_files, [:order_id, :file_type]
  end
end
