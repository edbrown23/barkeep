class AddRecipes < ActiveRecord::Migration[6.1]
  def change
    create_table :recipes do |t|
      t.string :name

      t.timestamps
    end
  end
end
