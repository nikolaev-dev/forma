class CreateTagSynonyms < ActiveRecord::Migration[8.1]
  def change
    create_table :tag_synonyms do |t|
      t.references :tag, null: false, foreign_key: true
      t.string :phrase, null: false
      t.string :normalized, null: false

      t.timestamps
    end

    add_index :tag_synonyms, :normalized, unique: true
  end
end
