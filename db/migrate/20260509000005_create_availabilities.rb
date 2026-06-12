class CreateAvailabilities < ActiveRecord::Migration[7.2]
  def change
    create_table :availabilities, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :clinic,  type: :uuid, foreign_key: true, null: false
      t.references :service, type: :uuid, foreign_key: true, null: false
      t.references :dentist, type: :uuid, foreign_key: { to_table: :users }, null: false

      t.date    :date,       null: false
      t.time    :starts_at,  null: false
      t.time    :ends_at,    null: false
      t.string  :status,     null: false, default: "available"
      t.timestamps
    end

    add_index :availabilities, [:dentist_id, :date, :starts_at], unique: true,
      name: "idx_availabilities_no_double_booking"

    add_check_constraint :availabilities,
      "status IN ('available', 'booked', 'cancelled', 'blocked')",
      name: "availabilities_status_check"
    add_check_constraint :availabilities,
      "ends_at > starts_at",
      name: "availabilities_time_order"
  end
end
