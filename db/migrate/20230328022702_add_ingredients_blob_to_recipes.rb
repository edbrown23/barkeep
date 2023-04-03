class AddIngredientsBlobToRecipes < ActiveRecord::Migration[7.0]
  def change
    add_column :recipes, :ingredients_blob, :jsonb, default: {}
  end
end
