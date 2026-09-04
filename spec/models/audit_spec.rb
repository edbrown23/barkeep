require 'rails_helper'

RSpec.describe Audit, type: :model do
  it_behaves_like 'a user-scoped model', :audit

  describe '#backup_name' do
    it 'reads the historical cocktail name from its snapshot' do
      audit = build(:audit, info: { 'cocktail_name' => 'Last Word', 'reagents' => [] })

      expect(audit.backup_name).to eq('Last Word')
    end
  end

  describe '#ephemeral_recipe?' do
    it 'is false for an ordinary persisted recipe even if the snapshot flag is true' do
      recipe = create(:recipe, source: '')
      audit = build(:audit, recipe: recipe, info: { 'ephemeral_recipe' => true, 'reagents' => [] })

      expect(audit).not_to be_ephemeral_recipe
    end

    it 'uses the snapshot flag for a drink-builder recipe' do
      recipe = create(:recipe, source: 'drink_builder')
      audit = build(:audit, recipe: recipe, info: { 'ephemeral_recipe' => true, 'reagents' => [] })

      expect(audit).to be_ephemeral_recipe
    end

    it 'defaults a missing snapshot flag to false' do
      recipe = create(:recipe, source: 'drink_builder')
      audit = build(:audit, recipe: recipe, info: { 'reagents' => [] })

      expect(audit).not_to be_ephemeral_recipe
    end
  end

  describe '#reagents' do
    it 'maps reagent snapshots and applies substitution defaults' do
      audit = build(
        :audit,
        info: {
          'reagents' => [
            {
              'reagent_name' => 'Barr Hill Gin',
              'amount_used' => 2,
              'unit_used' => 'oz',
              'description' => 'London dry',
              'reagent_id' => 123,
              'original_tags' => ['old_tom_gin', 'gin'],
              'substituted' => true
            },
            {
              'reagent_name' => 'Lime Juice',
              'amount_used' => 1,
              'unit_used' => 'oz',
              'reagent_id' => 456
            }
          ]
        }
      )

      gin, lime = audit.reagents

      expect(gin.to_h).to eq(
        name: 'Barr Hill Gin',
        amount: 2,
        unit: 'oz',
        description: 'London dry',
        reagent_id: 123,
        original_tags: 'old_tom_gin, gin',
        substituted: true
      )
      expect(lime.original_tags).to eq('')
      expect(lime.substituted).to be(false)
    end
  end

  describe 'rating details' do
    it 'returns nil when no rating has been recorded' do
      audit = build(:audit)

      expect(audit.star_count).to be_nil
      expect(audit.notes).to be_nil
    end

    it 'persists stars and notes without replacing either value' do
      audit = create(:audit)

      audit.set_rating(4)
      audit.set_notes('Better with less lime')
      audit.save!
      audit.reload

      expect(audit.star_count).to eq(4)
      expect(audit.notes).to eq('Better with less lime')
    end
  end
end
