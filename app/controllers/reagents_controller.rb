class ReagentsController < ApplicationController
  before_action :authenticate_user!

  before_action :set_reagent, only: [:show, :edit, :update, :destroy]

  def index
    search_term = search_params['search_term']

    if search_term.present? && search_term.size > 0
      @reagents = Reagent.for_user(current_user).where('name ILIKE ?', "%#{search_term}%").order(:name)
    else
      @reagents = Reagent.for_user(current_user).all.order(:name)
    end
  end

  def new
    @reagent = Reagent.new(user_id: current_user.id)
    @reagent_categories = ReagentCategory.all.order(:name)
    @possible_units = POSSIBLE_UNITS
  end

  def show
    reagent_amounts = ReagentAmount.for_user(current_user).where(reagent: @reagent)

    amounts = ReagentAmount.with_tags(@reagent.tags)
    @cocktails = Recipe.where(id: amounts.pluck(:recipe_id))
  end

  def edit
    @possible_units = POSSIBLE_UNITS
  end

  def refill
    # I don't know why this route sends the id as "reagent_id" instead of "id". probably some nested route magic
    reagent = Reagent.for_user(current_user).find_by(id: params['reagent_id'])
    reagent.update!(current_volume: reagent.current_volume + reagent.max_volume) if reagent.present?

    respond_to do |format|
      format.html { redirect_to reagent, notice: "#{reagent.name} refilled" }
      format.json do
        render json: {
          reagent_id: reagent.id,
          new_volume: reagent.current_volume,
          reagent_name: reagent.name
        }
      end
    end
  end

  def create
    parsed_params = parse_and_maybe_create_category(reagent_params)
    @reagent = Reagent.for_user(current_user).new(parsed_params)

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
          .permit(:name, :cost, :purchase_location, :max_volume_value, :current_volume_value, :volume_unit, :description, tags: [])
    end

    def search_params
      params.permit(:search_term)
    end
end