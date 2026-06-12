class RemoveTimeOrderConstraintFromAvailabilities < ActiveRecord::Migration[7.2]
  def change
    # The PG constraint compares UTC-stored values which breaks in any non-UTC timezone.
    # ends_after_starts validation in the model handles this correctly using local time.
    remove_check_constraint :availabilities, name: "availabilities_time_order"
  end
end
