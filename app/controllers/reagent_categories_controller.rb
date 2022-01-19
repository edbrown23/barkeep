class ReagentCategoriesController < ApplicationController
  def index
    @categories = ReagentCategory.all
  end

  def show
    @category = ReagentCategory.find(params[:id])
  end
end