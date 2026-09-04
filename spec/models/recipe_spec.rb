require 'rails_helper'

RSpec.describe Recipe, type: :model do
  it_behaves_like 'a user-scoped model', :recipe

  describe Recipe::Ingredient do
    describe '#unitless?' do
      it 'is true for unknown units' do
        ingredient = described_class.new(unit: 'unknown')

        expect(ingredient).to be_unitless
      end

      it 'is false for measured units' do
        ingredient = described_class.new(unit: 'oz')

        expect(ingredient).not_to be_unitless
      end
    end

    describe '#required_volume' do
      it 'builds a measured volume from its amount and unit' do
        ingredient = described_class.new(amount: 1.5, unit: 'oz')

        expect(ingredient.required_volume).to eq(Measured::Volume.new(1.5, 'oz'))
      end
    end

    describe '#reagent_amount' do
      it 'finds the persisted amount it came from' do
        amount = create(:reagent_amount)
        ingredient = described_class.new(reagent_amount_id: amount.id)

        expect(ingredient.reagent_amount).to eq(amount)
      end
    end

    describe '#optional?' do
      it 'defaults nil to false' do
        expect(described_class.new(optional: nil)).not_to be_optional
      end

      it 'preserves an explicit optional value' do
        expect(described_class.new(optional: true)).to be_optional
      end
    end
  end

  describe '#ingredients' do
    it 'returns an empty list when the blob has no ingredients' do
      expect(build(:recipe, ingredients_blob: {}).ingredients).to be_empty
    end

    it 'deserializes stored ingredient fields' do
      recipe = build(
        :recipe,
        ingredients_blob: {
          'ingredients' => [
            {
              'tags' => ['gin'],
              'amount' => 1.5,
              'unit' => 'oz',
              'reagent_amount_id' => 42,
              'optional' => true
            }
          ]
        }
      )

      expect(recipe.ingredients.first.to_h).to include(
        tags: ['gin'],
        amount: 1.5,
        unit: 'oz',
        reagent_amount_id: 42,
        optional: true
      )
    end
  end

  describe '#<<' do
    it 'persists an appended ingredient through a reload' do
      recipe = create(:recipe)
      amount = create(:reagent_amount, recipe: recipe, tags: ['gin'], amount: 2, unit: 'oz', optional: true)

      recipe << amount.convert_to_blob
      recipe.save!

      expect(recipe.reload.ingredients.first.to_h).to include(
        tags: ['gin'],
        amount: amount.amount.to_s,
        unit: 'oz',
        reagent_amount_id: amount.id,
        optional: true
      )
    end
  end

  describe '#clear_ingredients' do
    it 'removes persisted ingredients through a reload' do
      recipe = create(
        :recipe,
        ingredients_blob: { 'ingredients' => [{ 'tags' => ['gin'], 'amount' => 1, 'unit' => 'oz' }] }
      )

      recipe.clear_ingredients
      recipe.save!

      expect(recipe.reload.ingredients).to be_empty
    end
  end

  describe '#tags' do
    it 'flattens tags from every stored ingredient' do
      recipe = build(
        :recipe,
        ingredients_blob: {
          'ingredients' => [
            { 'tags' => ['gin', 'london_dry_gin'] },
            { 'tags' => ['lime'] }
          ]
        }
      )

      expect(recipe.tags).to eq(['gin', 'london_dry_gin', 'lime'])
    end
  end

  describe '.by_tag' do
    it 'searches generated tags and translates underscores to slashes' do
      matching = create(
        :recipe,
        ingredients_blob: {
          'ingredients' => [{ 'tags' => ['orange/liqueur'], 'amount' => 1, 'unit' => 'oz' }]
        }
      )
      create(
        :recipe,
        ingredients_blob: {
          'ingredients' => [{ 'tags' => ['dark/rum'], 'amount' => 1, 'unit' => 'oz' }]
        }
      )

      expect(described_class.by_tag('orange_liqueur')).to contain_exactly(matching)
    end
  end

  describe 'proposal attributes' do
    it 'persists typed accessors in extras' do
      user = create(:user)
      recipe = create(:recipe, proposed_to_be_shared: true, proposer_user_id: user.id)

      recipe.reload

      expect(recipe.proposed_to_be_shared).to be(true)
      expect(recipe.proposer_user_id).to eq(user.id)
    end
  end

  describe '#global_cocktail_families' do
    it 'only returns shared families attached to the recipe' do
      user = create(:user)
      recipe = create(:recipe, user: user)
      shared_family = create(:cocktail_family, user: nil)
      private_family = create(:cocktail_family, user: user)
      create(:cocktail_family_joiner, recipe: recipe, cocktail_family: shared_family)
      create(:cocktail_family_joiner, recipe: recipe, cocktail_family: private_family, user: user)

      expect(recipe.global_cocktail_families).to contain_exactly(shared_family)
    end
  end

  describe 'recipe relationships' do
    it 'traverses between parent and child recipes' do
      parent = create(:recipe)
      child = create(:recipe, parent: parent)

      expect(parent.children).to contain_exactly(child)
      expect(child.parent).to eq(parent)
    end

    it 'destroys ingredient amounts with the recipe' do
      recipe = create(:recipe)
      amount = create(:reagent_amount, recipe: recipe)

      recipe.destroy!

      expect(ReagentAmount.exists?(amount.id)).to be(false)
    end
  end

  describe '#matching_reagents' do
    it 'maps each required amount to overlapping bottles from the requested user' do
      user = create(:user)
      recipe = create(:recipe, user: user)
      gin_amount = create(:reagent_amount, recipe: recipe, user: user, tags: ['gin'])
      citrus_amount = create(:reagent_amount, recipe: recipe, user: user, tags: ['citrus'])
      gin = create(:reagent, user: user, tags: ['gin', 'london_dry_gin'])
      citrus = create(:reagent, user: user, tags: ['lime', 'citrus'])
      create(:reagent, user: create(:user), tags: ['gin'])

      expect(recipe.matching_reagents(user)).to eq(
        gin_amount => [gin],
        citrus_amount => [citrus]
      )
    end
  end

  describe '#user_can_make?' do
    let(:user) { create(:user) }
    let(:recipe) { create(:recipe, user: user) }

    def add_ingredient(recipe, user, optional: false)
      amount = create(
        :reagent_amount,
        recipe: recipe,
        user: user,
        tags: ['gin'],
        amount: 2,
        unit: 'oz',
        optional: optional
      )
      recipe << amount.convert_to_blob
      recipe.save!
    end

    it 'is true when the user has enough of every required ingredient' do
      add_ingredient(recipe, user)
      create(:reagent, user: user, tags: ['gin'], current_volume_value: 2, current_volume_unit: 'oz')

      expect(recipe.user_can_make?(user)).to be(true)
    end

    it 'is false when a matching bottle does not have enough volume' do
      add_ingredient(recipe, user)
      create(:reagent, user: user, tags: ['gin'], current_volume_value: 1, current_volume_unit: 'oz')

      expect(recipe.user_can_make?(user)).to be(false)
    end

    it 'does not require a matching bottle for an optional ingredient' do
      add_ingredient(recipe, user, optional: true)

      expect(recipe.user_can_make?(user)).to be(true)
    end
  end

  describe '#ephemeral?' do
    it 'is true for drink-builder recipes' do
      expect(build(:recipe, source: 'drink_builder')).to be_ephemeral
    end

    it 'is false for ordinary recipes' do
      expect(build(:recipe, source: '')).not_to be_ephemeral
    end
  end
end
