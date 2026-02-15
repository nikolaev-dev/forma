class CreateReferenceImages < ActiveRecord::Migration[8.0]
  def change
    create_table :reference_images do |t|
      t.references :training_batch, null: false, foreign_key: true
      t.string :status, null: false, default: "uploaded"
      t.jsonb :ai_analysis_claude, default: {}
      t.jsonb :ai_analysis_openai, default: {}
      t.string :selected_provider
      t.text :curated_prompt
      t.references :collection, null: true, foreign_key: true
      t.references :design, null: true, foreign_key: true
      t.text :curator_notes

      t.timestamps
    end

    add_index :reference_images, :status
  end
end
