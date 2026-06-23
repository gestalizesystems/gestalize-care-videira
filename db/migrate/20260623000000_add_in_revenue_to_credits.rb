class AddInRevenueToCredits < ActiveRecord::Migration[7.2]
  def change
    add_column :credits, :in_revenue, :boolean, null: false, default: true
  end
end
