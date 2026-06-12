class CreateBookingGroups < ActiveRecord::Migration[7.2]
  def change
    create_table :booking_groups, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :clinic,         type: :uuid, foreign_key: true, null: false
      t.references :patient,        type: :uuid, foreign_key: { to_table: :users }, null: false
      t.references :discount_rule,  type: :uuid, foreign_key: true, null: true

      t.integer :subtotal_cents,  null: false
      t.integer :discount_cents,  null: false, default: 0
      t.integer :total_cents,     null: false
      t.string  :status,          null: false, default: "pending"
      t.timestamps
    end

    add_check_constraint :booking_groups,
      "status IN ('pending', 'confirmed', 'cancelled', 'expired')",
      name: "booking_groups_status_check"
    add_check_constraint :booking_groups,
      "discount_cents >= 0",
      name: "booking_groups_discount_non_negative"
    add_check_constraint :booking_groups,
      "total_cents > 0",
      name: "booking_groups_total_positive"
  end
end
