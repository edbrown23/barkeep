class AddUnitsToReagents < ActiveRecord::Migration[6.1]
  def change
    add_column :reagents, :max_volume_unit, :varchar, null: false
    add_column :reagents, :max_volume_value, :decimal, null: false, precision: 10, scale: 2
    remove_column :reagents, :max_volume, :decimal

    add_column :reagents, :current_volume_value, :decimal, null: false, precision: 10, scale: 2
    add_column :reagents, :current_volume_unit, :varchar, null: false
    remove_column :reagents, :current_volume_percentage, :decimal
  end
end
