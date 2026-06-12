class CreateDiscountRules < ActiveRecord::Migration[7.2]
  def change
    create_table :discount_rules, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :clinic, type: :uuid, foreign_key: true, null: false
      t.integer :min_slots,        null: false
      t.integer :discount_percent, null: false
      t.boolean :active,           null: false, default: true
      t.timestamps
    end

    add_index :discount_rules, [:clinic_id, :min_slots], unique: true,
      where: "active = true", name: "idx_discount_rules_unique_active"

    add_check_constraint :discount_rules,
      "min_slots > 0",
      name: "discount_rules_min_slots_positive"
    add_check_constraint :discount_rules,
      "discount_percent BETWEEN 1 AND 100",
      name: "discount_rules_percent_range"
  end
end
