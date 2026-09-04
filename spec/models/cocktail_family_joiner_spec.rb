require 'rails_helper'

RSpec.describe CocktailFamilyJoiner, type: :model do
  describe '.available_favorite_from' do
    it 'limits favorites by user, family name, and supplied recipe ids' do
      user = create(:user)
      other_user = create(:user)
      wanted_recipe = create(:recipe)
      outside_recipe = create(:recipe)
      favorites = create(
        :cocktail_family,
        name: Constants::COCKTAIL_FAVORITES_NAME,
        user: user
      )
      other_family = create(:cocktail_family, name: 'Party drinks', user: user)
      other_favorites = create(
        :cocktail_family,
        name: Constants::COCKTAIL_FAVORITES_NAME,
        user: other_user
      )
      matching = create(
        :cocktail_family_joiner,
        recipe: wanted_recipe,
        cocktail_family: favorites,
        user: user
      )
      create(:cocktail_family_joiner, recipe: outside_recipe, cocktail_family: favorites, user: user)
      create(:cocktail_family_joiner, recipe: wanted_recipe, cocktail_family: other_family, user: user)
      create(
        :cocktail_family_joiner,
        recipe: wanted_recipe,
        cocktail_family: other_favorites,
        user: other_user
      )

      expect(described_class.available_favorite_from(user, [wanted_recipe.id])).to contain_exactly(matching)
    end
  end
end
