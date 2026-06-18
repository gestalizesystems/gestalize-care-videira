class AddDiscountCentsToDiscountRules < ActiveRecord::Migration[7.2]
  def change
    add_column :discount_rules, :discount_cents, :integer, null: false, default: 0
    change_column_null :discount_rules, :discount_percent, true
  end
end
