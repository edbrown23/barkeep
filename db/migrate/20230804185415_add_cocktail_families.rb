class AddCocktailFamilies < ActiveRecord::Migration[7.0]
  def change
    create_table :cocktail_families do |t|
      t.string :name, null: false
      t.jsonb :facts, null: false, default: {}
      t.string :description
    end

    create_table :cocktail_family_joiners do |t|
      t.references :recipe, null: false
      t.references :cocktail_family, null: false
    end
  end
end
