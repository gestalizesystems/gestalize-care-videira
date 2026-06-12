class DeviseCreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :clinic, type: :uuid, foreign_key: true, null: true

      t.string :name,       null: false
      t.string :phone
      t.date   :birth_date
      t.string :cpf
      t.string :role,       null: false, default: "patient"

      # OmniAuth
      t.string :provider
      t.string :uid

      ## Devise
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at

      t.timestamps null: false
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :cpf,                  unique: true, where: "cpf IS NOT NULL"
    add_index :users, [:provider, :uid],     unique: true, where: "provider IS NOT NULL"

    add_check_constraint :users,
      "role IN ('owner', 'dentist', 'patient')",
      name: "users_role_check"
  end
end
