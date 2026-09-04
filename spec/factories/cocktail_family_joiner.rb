FactoryBot.define do
  factory :cocktail_family_joiner do
    recipe
    cocktail_family
    user { cocktail_family.user }
  end
end
