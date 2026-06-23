class CreateShiftTemplates < ActiveRecord::Migration[7.2]
  def change
    create_table :shift_templates, id: :uuid do |t|
      t.references :clinic, null: false, type: :uuid, foreign_key: true
      t.time    :starts_at,   null: false
      t.time    :ends_at,     null: false
      t.integer :price_cents, null: false, default: 0
      t.boolean :active,      null: false, default: true
      t.timestamps
    end

    # Até que data os turnos recorrentes já foram materializados em availabilities.
    add_column :clinics, :shifts_generated_until, :date
  end
end
