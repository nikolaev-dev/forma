class CreateCatalogSections < ActiveRecord::Migration[8.1]
  def change
    create_table :catalog_sections do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :section_type, null: false, default: "editorial"
      t.boolean :is_active, null: false, default: true
      t.integer :position, default: 0
      t.jsonb :rules, default: {}

      t.timestamps
    end

    add_index :catalog_sections, :slug, unique: true
    add_index :catalog_sections, :section_type
    add_index :catalog_sections, :position
  end
end
