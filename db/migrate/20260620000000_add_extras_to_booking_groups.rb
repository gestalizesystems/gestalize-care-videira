class AddExtrasToBookingGroups < ActiveRecord::Migration[7.2]
  def change
    add_column :booking_groups, :extras, :jsonb, null: false, default: []
  end
end
