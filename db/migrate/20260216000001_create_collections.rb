class CreateCollections < ActiveRecord::Migration[8.0]
  def change
    create_table :collections do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :collection_type, null: false, default: "regular"
      t.integer :edition_size
      t.integer :stock_remaining
      t.boolean :is_active, null: false, default: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :collections, :slug, unique: true
  end
end
