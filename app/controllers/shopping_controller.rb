class ShoppingController < ApplicationController
  before_action :authenticate_user!

  def index
    cocktails = CocktailAvailabilityService.new(Recipe.where(category: 'cocktail'), current_user)
    counts = cocktails.available_counts
    
    one_off_cocktails = counts.select { |_, count| count[:required] - count[:available] == 1 }
    @one_off_cocktails = Recipe.where(id: one_off_cocktails.keys).index_by(&:id)

    @availability = one_off_cocktails

    @inverted_availability = one_off_cocktails.reduce({}) do |memo, (cid, avail)|
      memo[avail[:missing_tags]] ||= []
      memo[avail[:missing_tags]] << @one_off_cocktails[cid]
      memo
    end
  end
end