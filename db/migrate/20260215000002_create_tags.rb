class CreateTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.references :tag_category, null: false, foreign_key: true
      t.string :visibility, null: false, default: "public"
      t.string :kind, null: false, default: "generic"
      t.decimal :weight, precision: 6, scale: 3, null: false, default: 1.0
      t.boolean :is_banned, null: false, default: false
      t.string :banned_reason
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :tags, :slug, unique: true
    add_index :tags, :visibility
    add_index :tags, :kind
    add_index :tags, :is_banned

    # GIN trigram index for autocomplete
    execute <<-SQL
      CREATE INDEX index_tags_on_name_trigram ON tags USING gin (name gin_trgm_ops);
    SQL
  end
end
