FactoryBot.define do
  factory :recipe do
    user { nil }
    name { 'cocktail' }
    category { 'cocktail' }
  end
end
