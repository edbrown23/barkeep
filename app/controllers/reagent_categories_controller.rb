class ReagentCategoriesController < ApplicationController
  before_action :authenticate_user!, only: [:edit, :update]
  before_action :validate_admin!, only: [:edit, :update]

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

  def edit
    @category = find_by_external_id_or_pk(params[:id])
  end

  def update
    @category = find_by_external_id_or_pk(params[:id])
    params = update_params

    # need to find all references to this category and rewrite them
    ReagentCategory.transaction do
      old_external_id = @category.external_id

      ReagentAmount.with_tags([old_external_id]).each do |amount|
        amount.tags.map! { |t| t == old_external_id ? params[:external_id] : t }
        amount.save!
      end

      Reagent.with_tags([old_external_id]).each do |reagent|
        reagent.tags.map! { |t| t == old_external_id ? params[:external_id] : t }
        reagent.save!
      end

      @category.update!(params)
    end

    redirect_to @category
  end

  def find_by_external_id_or_pk(id)
    begin
      ReagentCategory.find(Integer(id))
    rescue ArgumentError
      ReagentCategory.find_by(external_id: params[:id])
    end
  end

  private

  def validate_admin!
    redirect_to '/reagent_categories' unless current_user.admin?
  end

  def update_params
    params.require(:reagent_category).permit(:name, :description, :external_id)
  end
end