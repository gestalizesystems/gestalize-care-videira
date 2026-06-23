class CreateExtras < ActiveRecord::Migration[7.2]
  def change
    create_table :extras, id: :uuid do |t|
      t.references :clinic, type: :uuid, null: false, foreign_key: true
      t.string  :name,        null: false
      t.integer :price_cents, null: false, default: 0
      t.boolean :active,      null: false, default: true
      t.timestamps
    end
  end
end
