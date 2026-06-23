class AddDiscountPerSlotToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :discount_per_slot_cents, :integer, null: false, default: 0
  end
end
