FactoryBot.define do
  factory :reagent do
    name { '' }
    external_id { name.underscore }
    user { nil }
    max_volume_value { '750' }
    max_volume_unit { 'ml' }
    current_volume_value { '750' }
    current_volume_unit { 'ml' }
    tags { [] }
  end
end