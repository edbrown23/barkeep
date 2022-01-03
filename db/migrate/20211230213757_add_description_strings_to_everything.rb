class AddDescriptionStringsToEverything < ActiveRecord::Migration[6.1]
  def change
    add_column :recipes, :description, :text
    add_column :reagent_amounts, :description, :text
    add_column :reagent_categories, :description, :text
    add_column :reagents, :description, :text
  end
end
