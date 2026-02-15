class CreateCatalogItems < ActiveRecord::Migration[8.1]
  def change
    create_table :catalog_items do |t|
      t.references :catalog_section, null: false, foreign_key: true
      t.string :item_type, null: false
      t.bigint :item_id, null: false
      t.integer :position, default: 0
      t.boolean :pinned, default: false

      t.timestamps
    end

    add_index :catalog_items, [ :item_type, :item_id ]
    add_index :catalog_items, :position
  end
end
