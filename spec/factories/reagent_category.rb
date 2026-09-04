FactoryBot.define do
  factory :reagent_category do
    sequence(:name) { |number| "Category #{number}" }
    sequence(:external_id) { |number| "category_#{number}" }
  end
end
