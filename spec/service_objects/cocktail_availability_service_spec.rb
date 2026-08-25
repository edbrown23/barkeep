require 'rails_helper'

describe 'CocktailAvailabilityService' do
  include_context "basic users"

  let!(:all_port) { create(:recipe, user: test_user) }
  let!(:the_port) { create(:reagent_amount, recipe: all_port, tags: ['port'], amount: '4') }

  let!(:empty_port) { create(:reagent, name: 'Tawny', user: test_user, tags: ['port'], current_volume_value: '10' )}

  let(:service) { CocktailAvailabilityService.new(Recipe.where(category: 'cocktail'), test_user) }

  before do
    all_port << the_port.convert_to_blob
    all_port.save!
  end

  it "calculates under volume bottles" do
    expect(service.cocktail_availability(all_port)[:under_volume_tags]).to include('port')
  end
end
