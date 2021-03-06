class ReagentsController < ApplicationController
  before_action :authenticate_user!

  before_action :set_reagent, only: [:show, :edit, :update, :destroy]

  def index
    search_term = search_params['search_term']

    if search_term.present? && search_term.size > 0
      @reagents = Reagent.for_user(current_user).where('name ILIKE ?', "%#{search_term}%").order(:id)
    else
      @reagents = Reagent.for_user(current_user).all.order(:id)
    end
  end

  def new
    @reagent = Reagent.new(user_id: current_user.id)
    @reagent_categories = ReagentCategory.for_user(current_user).all
  end

  def show
    reagent_amounts = ReagentAmount.for_user(current_user).where(reagent: @reagent)

    categories_amounts = []
    categories_amounts = ReagentAmount.for_user(current_user).where(reagent_category: @reagent.reagent_category) if @reagent.reagent_category.present?
    @cocktails = Recipe.for_user(current_user).where(id: reagent_amounts.pluck(:recipe_id) + categories_amounts.pluck(:recipe_id))
  end

  def edit
    @reagent_categories = ReagentCategory.for_user(current_user).all
  end

  def refill
    # I don't know why this route sends the id as "reagent_id" instead of "id". probably some nested route magic
    reagent = Reagent.for_user(current_user).find_by(id: params['reagent_id'])
    reagent.update!(current_volume_percentage: 1.0) if reagent.present?

    respond_to do |format|
      format.json do
        render json: {
          reagent_id: reagent.id,
          new_volume: reagent.current_volume_percentage * (reagent.max_volume || 0.0),
          reagent_name: reagent.name
        }
      end
    end
  end

  def create
    parsed_params = parse_and_maybe_create_category(reagent_params)
    @reagent = Reagent.for_user(current_user).new(parsed_params)
    @reagent_categories = ReagentCategory.for_user(current_user).all

    respond_to do |format|
      if @reagent.save
        # TODO: handle the notice
        format.html { redirect_to @reagent, notice: "#{@reagent.name} was successfully created" }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    parsed_params = parse_and_maybe_create_category(reagent_params)

    respond_to do |format|
      if @reagent.update(parsed_params)
        # TODO: handle the notice
        format.html { redirect_to @reagent, notice: "#{@reagent.name} was successfully updated" }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  private
    def parse_and_maybe_create_category(params)
      # setting an existing category should always win, so if it's present and a valid primary_key then set it
      # otherwise try to create a new category if one was passed in
      # lastly, if there's no new category and the user chose "-1", that means they want to clear the category
      if params[:existing_reagent_category_id].present? && params[:existing_reagent_category_id].to_i > 0
        params[:reagent_category_id] = params[:existing_reagent_category_id]
      elsif params[:new_category_name].present?
        new_category = ReagentCategory.create(name: params.delete(:new_category_name), user_id: current_user.id)
        params[:reagent_category_id] = new_category.id
      elsif params[:existing_reagent_category_id].present? && params[:existing_reagent_category_id].to_i == -1
        params[:reagent_category_id] = nil
      end

      params.except(:existing_reagent_category_id, :new_category_name)
    end

    def set_reagent
      # TODO: handle 404
      @reagent = Reagent.for_user(current_user).find(params[:id])
    end

    def reagent_params
      # I bet we could pull this from the model, that would be cool
      params
        .require(:reagent)
          .permit(:name, :cost, :purchase_location, :max_volume, :current_volume_percentage, :existing_reagent_category_id, :new_category_name)
    end

    def search_params
      params.permit(:search_term)
    end
end