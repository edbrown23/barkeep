class ReagentsController < ApplicationController
  before_action :authenticate_user!

  before_action :set_reagent, only: [:show, :edit, :update, :destroy]

  BASIC_BOTTLES = [:lime_juice, :lemon_juice, :whiskey, :gin, :soda_water]

  def index
    search_term = search_params['search_term']
    tags_search = search_params['search_tags']
    show_empty = search_params['show_empty'] == 'on'

    initial_scope = Reagent.for_user(current_user).where(shopping_list: nil)

    if search_term.present? && search_term.size > 0
      initial_scope = initial_scope.where('name ILIKE ?', "%#{search_term}%")
    end

    if tags_search.present?
      initial_scope = initial_scope.with_tags(tags_search)
    end

    initial_scope = initial_scope.has_volume if !show_empty

    @reagents = initial_scope.order(:name)

    existing_basics = Reagent.for_user(current_user).with_tags(BASIC_BOTTLES).flat_map(&:tags).map(&:to_sym)
    @basics_missing = (BASIC_BOTTLES - existing_basics).map do |basic_tag|
      {
        name: basic_tag.to_s.titleize,
        tags: [basic_tag]
      }
    end

    available_tags = @reagents.pluck(:tags).flatten.uniq
    @reagent_categories = ReagentCategory.where(external_id: available_tags).order(:name)
  end

  def new
    @reagent = Reagent.new(user_id: current_user.id, max_volume_value: 750, current_volume_value: 750)
    @reagent_categories = ReagentCategory.all.order(:name)
    @possible_units = POSSIBLE_UNITS_ML
  end

  def show
    amounts = ReagentAmount.for_user_or_shared(current_user).with_tags(@reagent.tags)
    @cocktails = Recipe.where(id: amounts.pluck(:recipe_id)).page(params[:page])
    @availability = CocktailAvailabilityService.new(@cocktails, current_user)
  end

  def shopping_list_show
    @reagent = Reagent.for_user(current_user).find(params[:reagent_id])
    @shopping_lists = ShoppingList.for_user(current_user)
    @existing_shopping_list_map = Reagent.for_user(current_user).with_tags(@reagent.tags).pluck(:shopping_list_id).uniq.compact
  end

  def edit
    @possible_units = POSSIBLE_UNITS_ML
  end

  def refill
    # I don't know why this route sends the id as "reagent_id" instead of "id". probably some nested route magic
    reagent = Reagent.for_user(current_user).find_by(id: params['reagent_id'])
    reagent.update!(current_volume: reagent.current_volume + reagent.max_volume) if reagent.present?

    respond_to do |format|
      format.html { redirect_to reagent, notice: "#{reagent.name} refilled" }
      format.json do
        render json: {
          action: 'refill',
          reagent_id: reagent.id,
          new_volume: reagent.current_volume,
          reagent_name: reagent.name
        }
      end
    end
  end

  def empty
    reagent = Reagent.for_user(current_user).find_by(id: params['reagent_id'])
    reagent.update!(current_volume_value: 0) if reagent.present?

    respond_to do |format|
      format.html { redirect_to reagent, notice: "#{reagent.name} emptied" }
      format.json do
        render json: {
          action: 'empty',
          reagent_id: reagent.id,
          new_volume: reagent.current_volume,
          reagent_name: reagent.name
        }
      end
    end
  end

  def create
    parsed_params = parse_and_maybe_create_category(reagent_params)
    @reagent = Reagent.for_user(current_user).new(parsed_params.except(:redirect_path))
    @reagent_categories = ReagentCategory.all.order(:name)
    @possible_units = POSSIBLE_UNITS_ML

    respond_to do |format|
      if @reagent.save
        if params[:commit] == "Create Bottle and add another"
          format.html { redirect_to new_reagent_path, notice: "#{@reagent.name} was successfully created" }
        else
          # TODO: handle the notice
          format.html { redirect_to @reagent, notice: "#{@reagent.name} was successfully created" }
        end
      else
        format.html { render :new, status: :unprocessable_entity, notice: "Errors creating your bottle: #{@reagent.errors.first(5)}" }
      end
    end
  end

  def update
    parsed_params = parse_and_maybe_create_category(reagent_params)
    redirect_path = parsed_params.delete(:redirect_path)
    @possible_units = POSSIBLE_UNITS_ML

    respond_to do |format|
      if @reagent.update(parsed_params)
        if redirect_path.present?
          format.html { redirect_to redirect_path, notice: "#{@reagent.name} was successfully updated" }
        else
          format.html { redirect_to @reagent, notice: "#{@reagent.name} was successfully updated" }
        end
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @reagent.destroy if @reagent.present?

    respond_to do |format|
      format.html { redirect_to '/reagents', alert: "#{@reagent.name} deleted!" }
    end
  end

  private

  def parse_and_maybe_create_category(params)
    params[:tags] = params[:tags].map(&:strip).map { |tag| Lib.to_external_id(tag) }

    params[:tags].each do |tag|
      ReagentCategory.find_or_create_by(external_id: tag) { |created_model| created_model.name = tag.titleize }
    end
    
    params[:external_id] = Lib.to_external_id(params[:name])

    params[:max_volume_unit] = params[:volume_unit]
    params[:current_volume_unit] = params[:volume_unit]
    params.delete(:volume_unit)

    params
  end

  def set_reagent
    # TODO: handle 404
    @reagent = Reagent.for_user(current_user).find(params[:id])
    @reagent_categories = ReagentCategory.all.order(:name)
  end

  def reagent_params
    # I bet we could pull this from the model, that would be cool
    params
      .require(:reagent)
        .permit(:name, :cost, :purchase_location, :max_volume_value, :current_volume_value, :volume_unit, :description, :redirect_path, tags: [])
  end

  def search_params
    params.permit(:search_term, :commit, :show_empty, search_tags: [])
  end
end