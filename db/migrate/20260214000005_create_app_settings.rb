class CreateAppSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :app_settings do |t|
      t.string :key, null: false
      t.jsonb :value, null: false, default: {}
      t.references :updated_by_user, foreign_key: { to_table: :users }

      t.datetime :updated_at
    end

    add_index :app_settings, :key, unique: true
  end
end
