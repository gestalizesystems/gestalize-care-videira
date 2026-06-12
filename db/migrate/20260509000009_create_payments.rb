class CreatePayments < ActiveRecord::Migration[7.2]
  def change
    create_table :payments, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :clinic,        type: :uuid, foreign_key: true, null: false
      t.references :booking_group, type: :uuid, foreign_key: true, null: false, index: { unique: true }

      t.integer  :amount_cents,      null: false
      t.string   :status,            null: false, default: "pending"
      t.string   :gateway,           null: false, default: "mercadopago"
      t.string   :gateway_id
      t.text     :pix_qr_code
      t.string   :pix_qr_url
      t.datetime :expires_at
      t.datetime :paid_at
      t.timestamps
    end

    add_index :payments, :gateway_id, unique: true, where: "gateway_id IS NOT NULL"

    add_check_constraint :payments,
      "status IN ('pending', 'paid', 'failed', 'cancelled', 'expired')",
      name: "payments_status_check"
    add_check_constraint :payments,
      "amount_cents > 0",
      name: "payments_amount_positive"
  end
end
