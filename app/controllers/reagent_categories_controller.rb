class ReagentCategoriesController < ApplicationController
  before_action :authenticate_user!

  def index
    @categories = ReagentCategory.all
  end

  def show
    @category = ReagentCategory.find(params[:id])

    amounts = ReagentAmount.where(reagent_category: @category)
    @cocktails = Recipe.where(id: amounts.pluck(:recipe_id))
  end
end