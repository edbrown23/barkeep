class AddUserIdToFamilies < ActiveRecord::Migration[7.0]
  def change
    add_reference :cocktail_families, :user, foreign_key: true, required: false 
    add_reference :cocktail_family_joiners, :user, foreign_key: true, required: false 
  end
end
