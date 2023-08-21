# == Schema Information
#
# Table name: cocktail_families
#
#  id          :bigint           not null, primary key
#  name        :string           not null
#  facts       :jsonb            not null
#  description :string
#  user_id     :bigint
#
# Indexes
#
#  index_cocktail_families_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class CocktailFamily < ApplicationRecord
  include UserScopable

  has_many :cocktail_family_joiners
  has_many :recipes, through: :cocktail_family_joiners
  belongs_to :user, optional: true

  def self.users_favorites(current_user)
    for_user(current_user).find_or_create_by(name: 'Favorites')
  end
end
