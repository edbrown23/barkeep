FactoryBot.define do
  factory :shopping_list do
    sequence(:name) { |number| "Shopping List #{number}" }
    user
  end
end
