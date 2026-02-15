class CreateDesignTags < ActiveRecord::Migration[8.1]
  def change
    create_table :design_tags do |t|
      t.references :design, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.string :source, null: false, default: "user"

      t.timestamps
    end

    add_index :design_tags, [ :design_id, :tag_id ], unique: true
  end
end
