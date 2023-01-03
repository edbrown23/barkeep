class ReagentCategoriesController < ApplicationController
  before_action :authenticate_user!, only: [:edit, :update, :new, :create]
  before_action :validate_admin!, only: [:edit, :update, :new, :create]

  def index
    search_term = search_params['search_term']

    if search_term.present? && search_term.size > 0
      @categories = ReagentCategory.where('name ILIKE ?', search_term).order(:name)
    else
      @categories = ReagentCategory.all.order(:name)
    end
  end

  def show
    @category = find_by_external_id_or_pk(params[:id])
    @reference_bottles = @category.reference_bottles

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

  def new
    @category = ReagentCategory.new
  end

  def create
    @category = ReagentCategory.new(update_params)

    respond_to do |format|
      if @category.save
        format.html { redirect_to @category, notice: "#{@category.external_id} was successfully created" }
      else
        format.html { render :new, status: :unprocessable_entity, alert: "#{@category.external_id} could not be created" }
      end
    end
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

    respond_to do |format|
      format.html { redirect_to @category, notice: "#{@category.external_id} updated!"}
    end
  end

  def find_by_external_id_or_pk(id)
    begin
      ReagentCategory.find(Integer(id))
    rescue ArgumentError
      ReagentCategory.find_by(external_id: params[:id])
    end
  end

  private

  def update_params
    params.require(:reagent_category).permit(:name, :description, :external_id).tap do |p|
      p[:external_id] = Lib.to_external_id(p[:external_id])
    end
  end

  def search_params
    params.permit(:search_term)
  end
end