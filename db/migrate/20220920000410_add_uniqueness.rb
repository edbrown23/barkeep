class AddUniqueness < ActiveRecord::Migration[6.1]
  def change
    add_index :reagents, :name, unique: true

    add_index :reagent_categories, :name, unique: true
  end
end
