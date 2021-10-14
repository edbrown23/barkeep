require 'rails_helper'

describe "ReagentAmount" do
  it "does absolutely basic rails stuff" do
    recipe = Recipe.create!
    reagent = Reagent.create!

    reagentAmount = ReagentAmount.create!(recipe: recipe, reagent: reagent)
    expect(reagentAmount.recipe_id).to eq(recipe.id)
    expect(reagentAmount.reagent_id).to eq(reagent.id)
  end
end