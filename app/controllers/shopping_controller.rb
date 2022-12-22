class ShoppingController < ApplicationController
  before_action :authenticate_user!

  def index
    cocktails = CocktailAvailabilityService.new(Recipe.where(category: 'cocktail'), current_user)
    counts = cocktails.available_counts
    
    one_off_ids = counts.select { |_, count| count[:required] - count[:available] == 1 }
    @one_off_cocktails = Recipe.where(id: one_off_ids.keys)

    
  end
end