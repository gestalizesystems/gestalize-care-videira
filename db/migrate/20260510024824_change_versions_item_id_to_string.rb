class ChangeVersionsItemIdToString < ActiveRecord::Migration[7.2]
  def up
    remove_index :versions, %i[item_type item_id]
    change_column :versions, :item_id, :string, null: false
    add_index :versions, %i[item_type item_id]
  end

  def down
    remove_index :versions, %i[item_type item_id]
    change_column :versions, :item_id, :bigint, null: false
    add_index :versions, %i[item_type item_id]
  end
end
