class CreateManualRevenueEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :manual_revenue_entries, id: :uuid do |t|
      t.references :clinic,     type: :uuid, null: false, foreign_key: true
      t.references :client,     type: :uuid, null: false, foreign_key: { to_table: :users }
      t.references :created_by, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.integer :amount_cents, null: false
      t.string  :category,     null: false
      t.date    :month,        null: false
      t.timestamps

      t.check_constraint "amount_cents > 0", name: "manual_revenue_entries_amount_positive"
      t.check_constraint "category IN ('turno', 'insumo')", name: "manual_revenue_entries_category_check"
    end
  end
end
