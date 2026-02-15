class CreateGenerationVariants < ActiveRecord::Migration[8.1]
  def change
    create_table :generation_variants do |t|
      t.references :generation, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :status, null: false, default: "created"
      t.text :composed_prompt, null: false
      t.bigint :seed
      t.string :mutation_summary
      t.jsonb :mutation_tags_added, default: []
      t.jsonb :mutation_tags_removed, default: []
      t.string :provider_job_id
      t.jsonb :provider_metadata, default: {}
      t.string :error_code
      t.text :error_message

      t.timestamps
    end

    add_index :generation_variants, [ :generation_id, :kind ], unique: true
    add_index :generation_variants, :status
    add_index :generation_variants, :provider_job_id
  end
end
