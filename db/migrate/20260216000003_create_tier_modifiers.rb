class CreateTierModifiers < ActiveRecord::Migration[8.0]
  def change
    create_table :tier_modifiers do |t|
      t.string :tier, null: false
      t.text :prompt_modifier, null: false
      t.text :identity_elements
      t.text :negative_prompt
      t.jsonb :settings, null: false, default: {}

      t.timestamps
    end

    add_index :tier_modifiers, :tier, unique: true
  end
end
