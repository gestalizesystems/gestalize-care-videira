class RenamePatientIdToDentistIdOnBookings < ActiveRecord::Migration[7.2]
  def change
    rename_column :bookings,        :patient_id, :dentist_id
    rename_column :booking_groups,  :patient_id, :dentist_id
  end
end
