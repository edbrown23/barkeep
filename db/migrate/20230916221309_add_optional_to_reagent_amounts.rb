class AddOptionalToReagentAmounts < ActiveRecord::Migration[7.0]
  def change
    add_column :reagent_amounts, :optional, :bool, default: false
  end
end
