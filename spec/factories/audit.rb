FactoryBot.define do
  factory :audit do
    recipe
    user
    info do
      {
        'cocktail_name' => recipe.name,
        'ephemeral_recipe' => false,
        'reagents' => []
      }
    end
  end
end
