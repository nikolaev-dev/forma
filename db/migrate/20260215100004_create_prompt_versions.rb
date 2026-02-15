class CreatePromptVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :prompt_versions do |t|
      t.references :prompt, null: false, foreign_key: true
      t.text :text, null: false
      t.references :changed_by_user, foreign_key: { to_table: :users }
      t.string :change_reason
      t.string :diff_summary
      t.jsonb :metadata, default: {}

      t.datetime :created_at, null: false
    end
  end
end
