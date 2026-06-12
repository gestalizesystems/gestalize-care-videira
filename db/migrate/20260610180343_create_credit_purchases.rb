class CreateCreditPurchases < ActiveRecord::Migration[7.2]
  def change
    create_table :credit_purchases, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user,   null: false, type: :uuid, foreign_key: true
      t.references :clinic, null: false, type: :uuid, foreign_key: true
      t.references :credit, type: :uuid, foreign_key: true
      t.integer  :amount_cents, null: false
      t.string   :status,       null: false, default: "pending"
      t.string   :gateway,      null: false, default: "infinitepay"
      t.string   :checkout_url
      t.string   :gateway_id
      t.datetime :expires_at
      t.datetime :paid_at

      t.timestamps
    end

    add_index :credit_purchases, :status
    add_check_constraint :credit_purchases, "amount_cents > 0", name: "credit_purchases_amount_positive"
  end
end
