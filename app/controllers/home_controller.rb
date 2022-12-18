class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    cocktails = CocktailAvailabilityService.new(Recipe.where(category: 'cocktail'), current_user)
    models = Recipe.where(id: cocktails.makeable_ids)
    @users_available = models.for_user(current_user)
    @shared_available = models.for_user(nil)

    @available_cocktails = @users_available + @shared_available
  end
end