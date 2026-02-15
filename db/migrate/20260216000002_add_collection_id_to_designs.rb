class AddCollectionIdToDesigns < ActiveRecord::Migration[8.0]
  def change
    add_reference :designs, :collection, null: true, foreign_key: true
  end
end
