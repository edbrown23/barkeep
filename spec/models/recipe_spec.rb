require 'rails_helper'

describe 'Recipe' do
  include_context "basic users"

  # all recipe setup
  let!(:singapore_sling) { create(:recipe, user: test_user) }
  let!(:gin) do
    ReagentAmount.create!(
      user: test_user,
      recipe: singapore_sling,
      amount: '1.5',
      unit: 'oz',
      tags: ['gin', 'london_dry_gin']
    )
  end
  let!(:benedictine) do
    ReagentAmount.create!(
      user: test_user,
      recipe: singapore_sling,
      amount: '1.5',
      unit: 'oz',
      tags: ['benedictine']
    )
  end
  let!(:cherry_heering) do
    ReagentAmount.create!(
      user: test_user,
      recipe: singapore_sling,
      amount: '1.5',
      unit: 'oz',
      tags: ['cherry_heering']
    )
  end
  let!(:lime_juice) do
    ReagentAmount.create!(
      user: test_user,
      recipe: singapore_sling,
      amount: '1.5',
      unit: 'oz',
      tags: ['lime_juice']
    )
  end
  let!(:soda_water) do
    ReagentAmount.create!(
      user: test_user,
      recipe: singapore_sling,
      amount: '4',
      unit: 'oz',
      tags: ['soda_water']
    )
  end

  # existing bottles setup
  let!(:barr_hill_gin) do
    Reagent.create!(
      name: 'Barr Hill Gin',
      external_id: 'barr_hill_gin',
      user: test_user,
      current_volume_unit: 'ml',
      current_volume_value: 750,
      max_volume_unit: 'ml',
      max_volume_value: 750,
      tags: ['gin']
    )
  end
  let!(:beefeater) do
    Reagent.create!(
      name: 'Beefeater Gin',
      external_id: 'beefeater_gin',
      user: test_user,
      current_volume_unit: 'ml',
      current_volume_value: 750,
      max_volume_unit: 'ml',
      max_volume_value: 750,
      tags: ['gin', 'london_dry_gin']
    )
  end
  let!(:cherry_heering_bottle) do
    Reagent.create!(
      name: 'Cherry Heering',
      external_id: 'cherry_heering',
      user: test_user,
      current_volume_unit: 'ml',
      current_volume_value: 750,
      max_volume_unit: 'ml',
      max_volume_value: 750,
      tags: ['cherry_heering']
    )
  end
  let!(:benedictine_bottle) do
    Reagent.create!(
      name: 'Benedictine',
      external_id: 'benedictine',
      user: test_user,
      current_volume_unit: 'ml',
      current_volume_value: 750,
      max_volume_unit: 'ml',
      max_volume_value: 750,
      tags: ['benedictine']
    )
  end
  let!(:lime_juice_bottle) do
    Reagent.create!(
      name: 'Lime Juice',
      external_id: 'lime_juice',
      user: test_user,
      current_volume_unit: 'ml',
      current_volume_value: 750,
      max_volume_unit: 'ml',
      max_volume_value: 750,
      tags: ['lime_juice']
    )
  end
  let!(:soda_water_bottle) do
    Reagent.create!(
      name: 'Soda Water',
      external_id: 'soda_water',
      user: test_user,
      current_volume_unit: 'ml',
      current_volume_value: 750,
      max_volume_unit: 'ml',
      max_volume_value: 750,
      tags: ['soda_water']
    )
  end

  it "finds all the available reagents" do
    expect(singapore_sling.matching_reagents(test_user).values.flatten).to include(soda_water_bottle)
  end

  it "can find all available drinks" do
    expect(Recipe.all_available(test_user)).to include(singapore_sling)
  end
end
