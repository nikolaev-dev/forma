class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.column :email, :citext
      t.string :phone
      t.string :name
      t.string :role, null: false, default: "user"
      t.string :status, null: false, default: "active"
      t.string :locale, null: false, default: "ru"
      t.string :timezone
      t.datetime :last_seen_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :users, :email, unique: true, where: "email IS NOT NULL"
    add_index :users, :phone, unique: true, where: "phone IS NOT NULL"
    add_index :users, :role
    add_index :users, :status
  end
end
