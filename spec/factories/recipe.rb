FactoryBot.define do
  factory :recipe do
    user { nil }
    sequence(:name) { |number| "Cocktail #{number}" }
    category { 'cocktail' }
  end
end
