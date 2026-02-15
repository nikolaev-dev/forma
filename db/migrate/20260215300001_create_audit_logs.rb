class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :actor_user, null: false, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.string :record_type
      t.bigint :record_id
      t.jsonb :before, default: {}
      t.jsonb :after, default: {}
      t.inet :ip

      t.datetime :created_at, null: false
    end

    add_index :audit_logs, [:record_type, :record_id]
    add_index :audit_logs, :action
    add_index :audit_logs, :created_at
  end
end
