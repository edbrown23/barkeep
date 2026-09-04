require 'rails_helper'

RSpec.describe ReagentAmount, type: :model do
  it_behaves_like 'a user-scoped model', :reagent_amount
  it_behaves_like 'a taggable model', :reagent_amount

  describe 'required volume' do
    it 'exposes the amount and unit as a measured volume' do
      amount = build(:reagent_amount, amount: 1.5, unit: 'oz')

      expect(amount.required_volume).to eq(Measured::Volume.new(1.5, 'oz'))
    end

    it 'rejects an invalid unit' do
      expect(build(:reagent_amount, unit: 'splash')).not_to be_valid
    end
  end

  describe '#reagent_categories' do
    it 'returns categories identified by its tags' do
      gin = create(:reagent_category, external_id: 'gin')
      citrus = create(:reagent_category, external_id: 'citrus')
      create(:reagent_category, external_id: 'rum')
      amount = create(:reagent_amount, tags: ['gin', 'citrus'])

      expect(amount.reagent_categories).to contain_exactly(gin, citrus)
    end
  end

  describe '#matching_reagents' do
    let(:user) { create(:user) }
    let(:shopping_list) { create(:shopping_list, user: user) }
    let(:amount) { create(:reagent_amount, user: user, tags: ['gin']) }
    let!(:inventory_gin) { create(:reagent, user: user, tags: ['gin']) }
    let!(:placeholder_gin) { create(:reagent, user: user, shopping_list: shopping_list, tags: ['gin']) }

    before do
      create(:reagent, user: create(:user), tags: ['gin'])
      create(:reagent, user: user, tags: ['rum'])
    end

    it 'returns matching bottles from the user inventory by default' do
      expect(amount.matching_reagents(user)).to contain_exactly(inventory_gin)
    end

    it 'returns matching placeholders from a selected shopping list' do
      expect(amount.matching_reagents(user, shopping_list)).to contain_exactly(placeholder_gin)
    end
  end

  describe '#to_placeholder_id' do
    it 'joins its tags in stored order' do
      expect(build(:reagent_amount, tags: ['orange_liqueur', 'triple_sec']).to_placeholder_id)
        .to eq('orange_liqueur,triple_sec')
    end
  end

  describe '#reagent_availability' do
    let(:user) { create(:user) }
    let(:amount) { create(:reagent_amount, user: user, amount: 2, unit: 'oz', tags: ['gin']) }

    it 'reports sufficient and insufficient matching bottles using compatible units' do
      enough = create(:reagent, user: user, tags: ['gin'], current_volume_value: 60, current_volume_unit: 'ml')
      short = create(:reagent, user: user, tags: ['gin'], current_volume_value: 30, current_volume_unit: 'ml')

      availability = amount.reagent_availability(user)

      expect(availability).to contain_exactly(
        { available: enough.current_volume, required: amount.required_volume, enough: true },
        { available: short.current_volume, required: amount.required_volume, enough: false }
      )
    end

    it 'adds an always-available garnish choice for an optional amount' do
      amount.update!(optional: true)

      expect(amount.reagent_availability(user)).to contain_exactly(
        {
          available: amount.required_volume,
          required: amount.required_volume,
          enough: true,
          garnish: true,
          optional: true
        }
      )
    end
  end

  describe '#unitless?' do
    it 'is true for unknown units' do
      expect(build(:reagent_amount, unit: 'unknown')).to be_unitless
    end

    it 'is false for measured amounts' do
      expect(build(:reagent_amount, unit: 'oz')).not_to be_unitless
    end
  end

  describe '#convert_to_blob' do
    it 'copies every ingredient field into a recipe ingredient' do
      amount = create(
        :reagent_amount,
        tags: ['gin'],
        amount: 1.5,
        unit: 'oz',
        description: 'London dry',
        optional: true
      )

      expect(amount.convert_to_blob.to_h).to eq(
        tags: ['gin'],
        amount: 1.5,
        unit: 'oz',
        description: 'London dry',
        reagent_amount_id: amount.id,
        optional: true
      )
    end
  end
end
