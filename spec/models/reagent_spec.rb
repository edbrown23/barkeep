require 'rails_helper'

RSpec.describe Reagent, type: :model do
  it_behaves_like 'a user-scoped model', :reagent
  it_behaves_like 'a taggable model', :reagent

  describe 'uniqueness' do
    let(:user) { create(:user) }

    before do
      create(:reagent, user: user, name: 'Barr Hill Gin', external_id: 'barr_hill_gin')
    end

    it 'requires names to be unique within a user inventory' do
      duplicate = build(:reagent, user: user, name: 'Barr Hill Gin', external_id: 'another_gin')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include('has already been taken')
    end

    it 'requires external ids to be unique within a user inventory' do
      duplicate = build(:reagent, user: user, name: 'Another Gin', external_id: 'barr_hill_gin')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:external_id]).to include('has already been taken')
    end

    it 'allows the same identity in another user inventory' do
      other_user_bottle = build(
        :reagent,
        user: create(:user),
        name: 'Barr Hill Gin',
        external_id: 'barr_hill_gin'
      )

      expect(other_user_bottle).to be_valid
    end
  end

  describe 'volume validation' do
    it 'rejects an invalid maximum volume unit' do
      expect(build(:reagent, max_volume_unit: 'bucket')).not_to be_valid
    end

    it 'rejects an invalid current volume unit' do
      expect(build(:reagent, current_volume_unit: 'bucket')).not_to be_valid
    end
  end

  describe '.real' do
    it 'excludes bottles that are shopping-list placeholders' do
      real_bottle = create(:reagent)
      placeholder = create(:reagent, shopping_list: create(:shopping_list))

      expect(described_class.real).to include(real_bottle)
      expect(described_class.real).not_to include(placeholder)
    end
  end

  describe '.has_volume' do
    it 'only includes bottles with a positive current volume' do
      available = create(:reagent, current_volume_value: 1)
      empty = create(:reagent, current_volume_value: 0)

      expect(described_class.has_volume).to include(available)
      expect(described_class.has_volume).not_to include(empty)
    end
  end

  describe '#subtract_usage' do
    it 'subtracts compatible units and persists in the bottle unit' do
      reagent = create(:reagent, current_volume_value: 750, current_volume_unit: 'ml')
      expected = (Measured::Volume.new(750, 'ml') - Measured::Volume.new(1, 'oz')).value.round(2)

      reagent.subtract_usage(Measured::Volume.new(1, 'oz'))

      expect(reagent.reload.current_volume).to eq(Measured::Volume.new(expected, 'ml'))
    end

    it 'clamps exact depletion to zero' do
      reagent = create(:reagent, current_volume_value: 1, current_volume_unit: 'oz')

      reagent.subtract_usage(Measured::Volume.new(1, 'oz'))

      expect(reagent.reload.current_volume_value).to be_zero
    end

    it 'clamps overuse to zero' do
      reagent = create(:reagent, current_volume_value: 1, current_volume_unit: 'oz')

      reagent.subtract_usage(Measured::Volume.new(2, 'oz'))

      expect(reagent.reload.current_volume_value).to be_zero
    end
  end

  describe '#add_usage' do
    it 'adds compatible units and persists in the bottle unit' do
      reagent = create(:reagent, current_volume_value: 750, current_volume_unit: 'ml')
      expected = (Measured::Volume.new(750, 'ml') + Measured::Volume.new(1, 'oz')).value.round(2)

      reagent.add_usage(Measured::Volume.new(1, 'oz'))

      expect(reagent.reload.current_volume).to eq(Measured::Volume.new(expected, 'ml'))
    end
  end

  describe '#unitless?' do
    it 'is true when the maximum volume unit is unknown' do
      expect(build(:reagent, max_volume_unit: 'unknown')).to be_unitless
    end

    it 'is false for measured bottles' do
      expect(build(:reagent, max_volume_unit: 'ml')).not_to be_unitless
    end
  end
end
