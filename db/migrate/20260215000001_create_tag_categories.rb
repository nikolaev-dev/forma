class CreateTagCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :tag_categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :position, null: false, default: 0
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end

    add_index :tag_categories, :slug, unique: true
    add_index :tag_categories, :position
  end
end
