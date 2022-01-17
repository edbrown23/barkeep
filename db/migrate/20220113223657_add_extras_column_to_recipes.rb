class AddExtrasColumnToRecipes < ActiveRecord::Migration[6.1]
  def change
    add_column :recipes, :extras, :jsonb
  end
end
