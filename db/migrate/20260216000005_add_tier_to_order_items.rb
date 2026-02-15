class AddTierToOrderItems < ActiveRecord::Migration[8.0]
  def change
    add_column :order_items, :tier, :string
  end
end
