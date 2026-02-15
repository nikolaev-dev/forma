class CreatePrompts < ActiveRecord::Migration[8.1]
  def change
    create_table :prompts do |t|
      t.references :design, null: false, foreign_key: true
      t.text :current_text, null: false

      t.timestamps
    end
  end
end
