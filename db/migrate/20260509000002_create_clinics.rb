class CreateClinics < ActiveRecord::Migration[7.2]
  def change
    create_table :clinics, id: :uuid, default: "gen_random_uuid()" do |t|
      t.string :name,  null: false
      t.string :cnpj,  null: false
      t.string :phone, null: false
      t.string :email, null: false
      t.string :logo_url
      t.timestamps
    end

    add_index :clinics, :cnpj, unique: true
  end
end
