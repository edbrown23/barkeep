FactoryBot.define do
  factory :reference_bottle do
    sequence(:name) { |number| "Reference bottle #{number}" }
    reagent_category
  end
end
