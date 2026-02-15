class CreateAnonymousIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :anonymous_identities do |t|
      t.string :anon_token_hash, null: false
      t.string :fingerprint_hash
      t.inet :last_ip
      t.datetime :last_seen_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :anonymous_identities, :anon_token_hash, unique: true
  end
end
