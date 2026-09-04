require 'rails_helper'

RSpec.describe CocktailFamily, type: :model do
  it_behaves_like 'a user-scoped model', :cocktail_family

  describe '.users_favorites' do
    it 'finds or creates one Favorites family for each user' do
      user = create(:user)
      other_user = create(:user)

      first_lookup = described_class.users_favorites(user)
      second_lookup = described_class.users_favorites(user)
      other_favorites = described_class.users_favorites(other_user)

      expect(first_lookup).to eq(second_lookup)
      expect(first_lookup.name).to eq(Constants::COCKTAIL_FAVORITES_NAME)
      expect(first_lookup.user).to eq(user)
      expect(other_favorites.user).to eq(other_user)
      expect(other_favorites).not_to eq(first_lookup)
    end
  end

  describe 'recipes' do
    it 'traverses recipes through family joiners' do
      family = create(:cocktail_family)
      recipe = create(:recipe)
      create(:cocktail_family_joiner, cocktail_family: family, recipe: recipe)

      expect(family.recipes).to contain_exactly(recipe)
    end
  end
end
