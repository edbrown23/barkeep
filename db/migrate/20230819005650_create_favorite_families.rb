class CreateFavoriteFamilies < ActiveRecord::Migration[7.0]
  def up
    User.all.each do |user|
      CocktailFamily.create!(
        name: 'Favorites',
        facts: {},
        description: 'Your favorite cocktails',
        user: user
      )
    end
  end

  def down
    CocktailFamily.where.not(user_id: null).destroy_all
  end
end
