class AddExternalIds < ActiveRecord::Migration[6.1]
  def change
    add_column :reagents, :external_id, :string
    add_index :reagents, :external_id, unique: true

    add_column :reagent_categories, :external_id, :string
    add_index :reagent_categories, :external_id, unique: true
  end
end
