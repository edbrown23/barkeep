class ShoppingController < ApplicationController
  before_action :authenticate_user!

  def index
    shared_cocktails = CocktailAvailabilityService.new(Recipe.for_user(nil).where(category: 'cocktail'), current_user)
    user_cocktails = CocktailAvailabilityService.new(Recipe.for_user(current_user).where(category: 'cocktail'), current_user)
    counts = shared_cocktails.available_counts.merge(user_cocktails.available_counts)
    
    one_off_cocktails = counts.select { |_, count| count[:required] - count[:available] == 1 }
    @one_off_cocktails = Recipe.where(id: one_off_cocktails.keys).index_by(&:id)

    @availability = one_off_cocktails

    @inverted_availability = one_off_cocktails.reduce({}) do |memo, (cid, avail)|
      memo[avail[:missing_tags]] ||= []
      memo[avail[:missing_tags]] << @one_off_cocktails[cid]
      memo
    end

    @low_bottles = Reagent.for_user(current_user).select do |bottle|
      (bottle.current_volume_value / bottle.max_volume_value) <= 0.1
    end
  end
end