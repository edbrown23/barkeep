# == Schema Information
#
# Table name: cocktail_family_joiners
#
#  id                 :bigint           not null, primary key
#  recipe_id          :bigint           not null
#  cocktail_family_id :bigint           not null
#  user_id            :bigint
#
# Indexes
#
#  index_cocktail_family_joiners_on_cocktail_family_id  (cocktail_family_id)
#  index_cocktail_family_joiners_on_recipe_id           (recipe_id)
#  index_cocktail_family_joiners_on_user_id             (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class CocktailFamilyJoiner < ApplicationRecord

  belongs_to :recipe
  belongs_to :cocktail_family
  belongs_to :user, optional: true

  def self.available_favorite_from(current_user, recipe_ids)
    joins(:cocktail_family)
      .where("cocktail_families.name = ?", Constants::COCKTAIL_FAVORITES_NAME)
      .where("cocktail_families.user_id = ?", current_user.id)
      .where("recipe_id IN (?)", recipe_ids)
  end
end
