class CreateGenerations < ActiveRecord::Migration[8.1]
  def change
    create_table :generations do |t|
      t.references :design, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.references :anonymous_identity, foreign_key: true
      t.string :source, null: false, default: "create"
      t.string :status, null: false, default: "created"
      t.string :provider, null: false
      t.jsonb :preset_snapshot, default: {}
      t.jsonb :tags_snapshot, default: {}
      t.string :error_code
      t.text :error_message
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end

    add_index :generations, :status
    add_index :generations, :source
  end
end
