require 'rails_helper'

RSpec.describe ReferenceBottle, type: :model do
  it 'requires a reagent category' do
    bottle = build(:reference_bottle, reagent_category: nil)

    expect(bottle).not_to be_valid
    expect(bottle.errors[:reagent_category]).to include('must exist')
  end

  it 'traverses to its reagent category' do
    category = create(:reagent_category)

    expect(create(:reference_bottle, reagent_category: category).reagent_category).to eq(category)
  end
end
