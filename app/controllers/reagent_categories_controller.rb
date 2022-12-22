class ReagentCategoriesController < ApplicationController
  def index
    @categories = ReagentCategory.all
  end

  def show
    @category = find_by_external_id_or_pk(params[:id])

    amounts = ReagentAmount.with_tags([@category.external_id])
    if user_signed_in?
      @cocktails = Recipe.where(id: amounts.pluck(:recipe_id))
    else
      @cocktails = Recipe.for_user(nil).where(id: amounts.pluck(:recipe_id))
    end
  end

  def find_by_external_id_or_pk(id)
    begin
      ReagentCategory.find(Integer(id))
    rescue ArgumentError
      ReagentCategory.find_by(external_id: params[:id])
    end
  end
end