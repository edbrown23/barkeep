require 'rails_helper'

RSpec.describe ReagentCategory, type: :model do
  describe '#reagents' do
    it 'returns matching bottles for the requested user only' do
      user = create(:user)
      category = create(:reagent_category, external_id: 'gin')
      matching = create(:reagent, user: user, tags: ['gin'])
      create(:reagent, user: user, tags: ['rum'])
      create(:reagent, user: create(:user), tags: ['gin'])

      expect(category.reagents(user)).to contain_exactly(matching)
    end
  end

  describe '#reagent_amounts' do
    it 'returns matching recipe amounts for the requested user only' do
      user = create(:user)
      category = create(:reagent_category, external_id: 'gin')
      matching = create(:reagent_amount, user: user, tags: ['gin'])
      create(:reagent_amount, user: user, tags: ['rum'])
      create(:reagent_amount, user: create(:user), tags: ['gin'])

      expect(category.reagent_amounts(user)).to contain_exactly(matching)
    end
  end

  describe '#dimension' do
    it 'uses its own id without an override' do
      category = create(:reagent_category)

      expect(category.dimension).to eq(category.id)
    end

    it 'uses the id of the configured override category' do
      parent_category = create(:reagent_category, external_id: 'whiskey')
      category = create(:reagent_category, override_dimension_external_id: 'whiskey')

      expect(category.dimension).to eq(parent_category.id)
    end
  end

  describe 'reference bottles' do
    it 'destroys dependent reference bottles with the category' do
      category = create(:reagent_category)
      bottle = create(:reference_bottle, reagent_category: category)

      category.destroy!

      expect(ReferenceBottle.exists?(bottle.id)).to be(false)
    end
  end
end
