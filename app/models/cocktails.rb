# This is pure business logic, since I'm dumb and decided to make models not cocktail specific
class Cocktails
  class << self
    def all_available
      # iterate recipes
      # check if I have enough volume in every reagent in the cocktail to make it
      all_cocktails = Recipe.where(category: 'cocktail')
      all_cocktails.filter do |cocktail|
        cocktail.reagent_amounts.all? do |amount|
          if amount.reagent_category.present?
            amount.reagent_category.reagents.any? { |category_reagent| category_reagent.ounces_available > amount.amount }
          else
            amount.reagent.ounces_available > amount.amount
          end
        end
      end
    end
  end
end