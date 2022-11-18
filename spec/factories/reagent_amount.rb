FactoryBot.define do
  factory :reagent_amount do
    user { nil }
    recipe { nil }
    amount { '1.5' }
    unit { 'oz' }
    tags { [] }
  end
end