class ReagentCategoriesController < ApplicationController
  before_action :authenticate_user!

  def index
    @categories = ReagentCategory.for_user(current_user).all
  end

  def show
    @category = ReagentCategory.for_user(current_user).find(params[:id])

    amounts = ReagentAmount.for_user(current_user).where(reagent_category: @category)
    @cocktails = Recipe.for_user(current_user).where(id: amounts.pluck(:recipe_id))
  end
end