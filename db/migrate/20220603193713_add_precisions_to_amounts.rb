class AddPrecisionsToAmounts < ActiveRecord::Migration[6.1]
  def change
    change_column :reagent_amounts, :amount, :decimal, precision: 10, scale: 2
    change_column_null :reagent_amounts, :amount, false
    change_column_null :reagent_amounts, :unit, false
  end
end
