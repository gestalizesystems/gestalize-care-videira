class AddPriceCentsToAvailabilitiesAndRelaxFKs < ActiveRecord::Migration[7.2]
  def change
    add_column :availabilities, :price_cents, :integer, null: false, default: 0

    # service and dentist are no longer required for room-rental slots
    change_column_null :availabilities, :service_id, true
    change_column_null :availabilities, :dentist_id, true
  end
end
