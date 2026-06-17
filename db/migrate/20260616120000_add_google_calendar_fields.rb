class AddGoogleCalendarFields < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :google_refresh_token, :text
    add_column :bookings, :google_event_id, :string
  end
end
