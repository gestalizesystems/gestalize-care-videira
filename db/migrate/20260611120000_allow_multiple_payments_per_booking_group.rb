class AllowMultiplePaymentsPerBookingGroup < ActiveRecord::Migration[7.2]
  def change
    remove_index :payments, :booking_group_id, unique: true, name: "index_payments_on_booking_group_id"
    add_index    :payments, :booking_group_id, name: "index_payments_on_booking_group_id"
  end
end
