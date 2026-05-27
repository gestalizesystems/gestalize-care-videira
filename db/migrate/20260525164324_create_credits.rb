class CreateCredits < ActiveRecord::Migration[7.2]
  def change
    create_table :credits, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user,                 type: :uuid, foreign_key: true, null: false
      t.references :clinic,               type: :uuid, foreign_key: true, null: false
      t.references :source_booking_group, type: :uuid, foreign_key: { to_table: :booking_groups }, null: true
      t.references :used_on_booking_group, type: :uuid, foreign_key: { to_table: :booking_groups }, null: true
      t.integer  :amount_cents, null: false
      t.string   :reason
      t.datetime :used_at

      t.timestamps
    end

    add_check_constraint :credits, "amount_cents > 0", name: "credits_amount_positive"
    add_index :credits, [:user_id, :clinic_id, :used_at]
  end
end
