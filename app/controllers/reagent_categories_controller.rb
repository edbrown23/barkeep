class ReagentCategoriesController < ApplicationController
  before_action :authenticate_user!

  def index
    @categories = ReagentCategory.all
  end

  def show
    @category = find_by_external_id_or_pk(params[:id])

    amounts = ReagentAmount.with_tags([@category.external_id])
    @cocktails = Recipe.where(id: amounts.pluck(:recipe_id))
  end

  def find_by_external_id_or_pk(id)
    begin
      ReagentCategory.find(Integer(id))
    rescue ArgumentError
      ReagentCategory.find_by(external_id: params[:id])
    end
  end
end