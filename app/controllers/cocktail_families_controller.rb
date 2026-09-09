class CocktailFamiliesController < ApplicationController
  # TODO: need some nuance on this check once there are global families
  before_action :authenticate_user!
  before_action :set_family

  def show
    @cocktails = @family.recipes.cocktails.visible_to(current_user).page(params[:page])
    @availability = CocktailAvailabilityService.new(@cocktails, current_user)
  end

  def update
  end

  def create
  end

  private

  def set_family
    @family = CocktailFamily.where(user_id: [nil, current_user.id]).find(params[:id])
  end
end