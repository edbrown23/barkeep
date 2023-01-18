class AddParentRecipe < ActiveRecord::Migration[6.1]
  def change
    add_column :recipes, :parent_id, :bigint
    add_index :recipes, :parent_id
  end
end
