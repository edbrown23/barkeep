class HoistAllIngredientBlobs < ActiveRecord::Migration[7.0]
  def hoist(user)
    initial_scope = user.present? ? Recipe.for_user(user) : Recipe.for_user(nil)

    initial_scope.includes(:reagent_amounts).in_batches do |recipes|
      recipes.each do |recipe|
        Recipe.transaction do
          recipe.clear_ingredients

          recipe.reagent_amounts.each { |ra| recipe << ra.convert_to_blob }

          recipe.save!
          Rails.logger.info("Hoisted #{recipe.name}")
        end
      end
    end
  end
  
  def change
    User.all.each do |u|
      hoist(u)
    end

    hoist(nil)
  end
end
