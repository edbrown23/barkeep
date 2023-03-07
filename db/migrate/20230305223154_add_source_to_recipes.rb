class AddSourceToRecipes < ActiveRecord::Migration[6.1]
  def change
    # I know this isn't the right way to do this, but I'm not dealing with lots of users right now
    add_column :recipes, :source, :string, required: true, default: ''
  end
end
