class AddReagentAmounts < ActiveRecord::Migration[6.1]
  def change
    create_table :reagent_amounts do |t|
      t.belongs_to :recipe
      t.belongs_to :reagent
      t.decimal :amount

      t.timestamps
    end
  end
end
