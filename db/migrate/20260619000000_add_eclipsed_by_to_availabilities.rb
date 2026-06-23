class AddEclipsedByToAvailabilities < ActiveRecord::Migration[7.2]
  def change
    add_column :availabilities, :eclipsed_by_id, :uuid
    add_index  :availabilities, :eclipsed_by_id
  end
end
