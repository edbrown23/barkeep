class HomeController < ApplicationController

  def index
    if user_signed_in?
      logged_in_index
    else
      logged_out_index
    end
  end

  def logged_in_index
    cocktails = CocktailAvailabilityService.new(Recipe.where(category: 'cocktail'), current_user)
    models = Recipe.where(id: cocktails.makeable_ids).includes(:reagent_amounts)
    @users_available = models.for_user(current_user).where('source != ALL(?::varchar[])', '{drink_builder}')
    @shared_available = models.for_user(nil)

    @available_cocktails = @users_available + @shared_available
  end

  def logged_out_index
    @shared_cocktails_count = Recipe.where(category: 'cocktail').for_user(nil).count
  end
end