class CreateTrainingBatches < ActiveRecord::Migration[8.0]
  def change
    create_table :training_batches do |t|
      t.string :name, null: false
      t.string :status, null: false, default: "uploaded"
      t.integer :images_count, null: false, default: 0
      t.references :created_by_user, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :training_batches, :status
  end
end
