class CreateTagRelations < ActiveRecord::Migration[8.1]
  def change
    create_table :tag_relations do |t|
      t.bigint :from_tag_id, null: false
      t.bigint :to_tag_id, null: false
      t.string :relation_type, null: false
      t.decimal :weight, precision: 6, scale: 3, default: 1.0

      t.timestamps
    end

    add_foreign_key :tag_relations, :tags, column: :from_tag_id
    add_foreign_key :tag_relations, :tags, column: :to_tag_id
    add_index :tag_relations, [ :from_tag_id, :to_tag_id, :relation_type ], unique: true, name: "idx_tag_relations_unique"
    add_index :tag_relations, :from_tag_id
    add_index :tag_relations, :to_tag_id
  end
end
