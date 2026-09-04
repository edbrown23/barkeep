FactoryBot.define do
  factory :reagent_amount do
    recipe
    user { recipe.user }
    amount { '1.5' }
    unit { 'oz' }
    tags { [] }
  end
end
