class CreateFillings < ActiveRecord::Migration[8.1]
  def change
    create_table :fillings do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :filling_type, null: false
      t.boolean :is_active, default: true
      t.jsonb :default_settings, default: {}

      t.timestamps
    end

    add_index :fillings, :slug, unique: true
    add_index :fillings, :filling_type
  end
end
