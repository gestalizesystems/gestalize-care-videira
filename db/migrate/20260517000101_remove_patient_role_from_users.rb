class RemovePatientRoleFromUsers < ActiveRecord::Migration[7.2]
  def up
    # Migrate existing patient users to dentist
    execute "UPDATE users SET role = 'dentist' WHERE role = 'patient'"

    # Replace check constraint to only allow owner and dentist
    remove_check_constraint :users, name: "users_role_check"
    add_check_constraint :users,
      "role::text = ANY (ARRAY['owner'::character varying, 'dentist'::character varying]::text[])",
      name: "users_role_check"

    # Change column default to dentist
    change_column_default :users, :role, from: "patient", to: "dentist"
  end

  def down
    execute "UPDATE users SET role = 'patient' WHERE role = 'dentist' AND clinic_id IS NULL"
    remove_check_constraint :users, name: "users_role_check"
    add_check_constraint :users,
      "role::text = ANY (ARRAY['owner'::character varying, 'dentist'::character varying, 'patient'::character varying]::text[])",
      name: "users_role_check"
    change_column_default :users, :role, from: "dentist", to: "patient"
  end
end
