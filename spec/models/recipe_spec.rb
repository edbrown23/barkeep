require 'rails_helper'

describe 'Recipe' do
  include_context "basic users"

  # all recipe setup
  let!(:singapore_sling) { create(:recipe, user: test_user) }
  let!(:gin) { create(:reagent_amount, user: test_user, recipe: singapore_sling, tags: ['gin', 'london_dry_gin']) }
  let!(:benedictine) { create(:reagent_amount, user: test_user, recipe: singapore_sling, tags: ['benedictine']) }
  let!(:cherry_heering) { create(:reagent_amount, user: test_user, recipe: singapore_sling, tags: ['cherry_heering']) }
  let!(:lime_juice) { create(:reagent_amount, user: test_user, recipe: singapore_sling, tags: ['lime_juice']) }
  let!(:soda_water) { create(:reagent_amount, user: test_user, recipe: singapore_sling, amount: '4', tags: ['soda_water']) }

  # existing bottles setup
  let!(:barr_hill_gin) { create(:reagent, name: 'Barr Hill Gin', user: test_user, tags: ['gin']) }
  let!(:beefeater) { create(:reagent, name: 'Beefeater Gin', user: test_user, tags: ['gin', 'london_dry_gin']) }
  let!(:cherry_heering_bottle) { create(:reagent, name: 'Cherry Heering', user: test_user, tags: ['cherry_heering']) }
  let!(:benedictine_bottle) { create(:reagent, name: 'Benedictine', user: test_user, tags: ['benedictine']) }
  let!(:lime_juice_bottle) { create(:reagent, name: 'Lime Juice', user: test_user, tags: ['lime_juice']) }
  let!(:soda_water_bottle) { create(:reagent, name: 'Soda Water', user: test_user, tags: ['soda_water']) }

  it "finds all the available reagents" do
    expect(singapore_sling.matching_reagents(test_user).values.flatten).to include(soda_water_bottle)
  end

  it "can find all available drinks" do
    expect(Recipe.all_available(test_user)).to include(singapore_sling)
  end
end
