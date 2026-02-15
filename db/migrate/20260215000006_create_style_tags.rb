class CreateStyleTags < ActiveRecord::Migration[8.1]
  def change
    create_table :style_tags do |t|
      t.references :style, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.boolean :is_primary, default: false

      t.timestamps
    end

    add_index :style_tags, [ :style_id, :tag_id ], unique: true
  end
end
