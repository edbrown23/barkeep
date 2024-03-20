class AddEmbeddingToRecipes < ActiveRecord::Migration[7.0]
  def change
    add_column :recipes, :embedding, :vector, limit: 500
  end
end
