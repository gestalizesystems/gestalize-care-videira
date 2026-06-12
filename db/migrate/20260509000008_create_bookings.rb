class CreateBookings < ActiveRecord::Migration[7.2]
  def change
    create_table :bookings, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :clinic,        type: :uuid, foreign_key: true, null: false
      t.references :booking_group, type: :uuid, foreign_key: true, null: false
      t.references :availability,  type: :uuid, foreign_key: true, null: false
      t.references :patient,       type: :uuid, foreign_key: { to_table: :users }, null: false

      t.integer :price_cents, null: false
      t.string  :status,      null: false, default: "pending"
      t.timestamps
    end

    add_index :bookings, :availability_id, unique: true,
      where: "status NOT IN ('cancelled')",
      name: "idx_bookings_availability_unique_active"

    add_check_constraint :bookings,
      "status IN ('pending', 'confirmed', 'cancelled')",
      name: "bookings_status_check"
    add_check_constraint :bookings,
      "price_cents >= 0",
      name: "bookings_price_non_negative"
  end
end
