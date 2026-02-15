class CreateUsageCounters < ActiveRecord::Migration[8.0]
  def change
    create_table :usage_counters do |t|
      t.references :user, null: true, foreign_key: true
      t.references :anonymous_identity, null: true, foreign_key: true
      t.date :period, null: false
      t.integer :generations_count, default: 0

      t.timestamps
    end

    add_index :usage_counters, [ :user_id, :period ], unique: true, where: "user_id IS NOT NULL", name: "idx_usage_counters_user_period"
    add_index :usage_counters, [ :anonymous_identity_id, :period ], unique: true, where: "anonymous_identity_id IS NOT NULL", name: "idx_usage_counters_anon_period"
  end
end
