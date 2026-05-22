class CreateCredits < ActiveRecord::Migration[7.2]
  def change
    create_table :credits do |t|
      t.timestamps
    end
  end
end
