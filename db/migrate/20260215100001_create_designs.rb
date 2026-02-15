class CreateDesigns < ActiveRecord::Migration[8.1]
  def change
    create_table :designs do |t|
      t.references :user, foreign_key: true
      t.bigint :source_design_id
      t.string :title
      t.string :slug
      t.string :visibility, null: false, default: "private"
      t.string :moderation_status, null: false, default: "ok"
      t.references :style, foreign_key: true
      t.text :base_prompt
      t.jsonb :metadata, default: {}
      t.decimal :popularity_score, precision: 10, scale: 4, default: 0

      t.timestamps
    end

    add_foreign_key :designs, :designs, column: :source_design_id
    add_index :designs, :slug, unique: true, where: "slug IS NOT NULL"
    add_index :designs, :visibility
    add_index :designs, :moderation_status
    add_index :designs, :source_design_id
    add_index :designs, :popularity_score

    # tsvector column for full-text search
    execute <<-SQL
      ALTER TABLE designs ADD COLUMN search_vector tsvector
        GENERATED ALWAYS AS (
          setweight(to_tsvector('russian', coalesce(title, '')), 'A') ||
          setweight(to_tsvector('russian', coalesce(base_prompt, '')), 'B')
        ) STORED;
    SQL

    execute <<-SQL
      CREATE INDEX index_designs_on_search_vector ON designs USING gin (search_vector);
    SQL
  end
end
