class CocktailFamiliesController < ApplicationController
  # TODO: need some nuance on this check once there are global families
  before_action :authenticate_user!
  before_action :set_family

  def show
    @cocktails = @family.recipes.page(params[:page])
    @availability = CocktailAvailabilityService.new(@cocktails, current_user)
  end

  def update
  end

  def create
  end

  private

  def set_family
    @family = CocktailFamily.find(params[:id])
  end
end