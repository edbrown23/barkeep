class AddUnitToReagentAmounts < ActiveRecord::Migration[6.1]
  def change
    add_column :reagent_amounts, :unit, :varchar
  end
end
