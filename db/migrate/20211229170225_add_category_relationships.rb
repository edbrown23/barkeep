class AddCategoryRelationships < ActiveRecord::Migration[6.1]
  def change
    add_reference :reagent_amounts, :reagent_category, index: true
    add_reference :reagents, :reagent_category, index: true
  end
end
