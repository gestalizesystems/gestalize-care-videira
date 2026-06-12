class CreateServices < ActiveRecord::Migration[7.2]
  def change
    create_table :services, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :clinic, type: :uuid, foreign_key: true, null: false
      t.string  :name,        null: false
      t.text    :description
      t.integer :duration_minutes, null: false
      t.integer :price_cents,      null: false
      t.boolean :active,           null: false, default: true
      t.timestamps
    end

    add_check_constraint :services,
      "duration_minutes > 0",
      name: "services_duration_positive"
    add_check_constraint :services,
      "price_cents >= 0",
      name: "services_price_non_negative"
  end
end
