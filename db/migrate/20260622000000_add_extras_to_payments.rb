class AddExtrasToPayments < ActiveRecord::Migration[7.2]
  def change
    add_column :payments, :extras, :jsonb, null: false, default: []
  end
end
