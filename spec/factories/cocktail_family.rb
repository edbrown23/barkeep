FactoryBot.define do
  factory :cocktail_family do
    sequence(:name) { |number| "Family #{number}" }
    facts { {} }
    user { nil }
  end
end
