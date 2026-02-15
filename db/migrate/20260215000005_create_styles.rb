class CreateStyles < ActiveRecord::Migration[8.1]
  def change
    create_table :styles do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :status, null: false, default: "draft"
      t.integer :position, null: false, default: 0
      t.decimal :popularity_score, precision: 10, scale: 4, null: false, default: 0
      t.jsonb :generation_preset, null: false, default: {}

      t.timestamps
    end

    add_index :styles, :slug, unique: true
    add_index :styles, :status
    add_index :styles, :position
    add_index :styles, :popularity_score
  end
end
