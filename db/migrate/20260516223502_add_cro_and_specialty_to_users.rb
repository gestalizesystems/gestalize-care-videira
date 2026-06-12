class AddCroAndSpecialtyToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :cro, :string
    add_column :users, :specialty, :string
  end
end
