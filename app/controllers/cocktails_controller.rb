class CocktailsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_cocktail, only: [:show, :edit, :update, :destroy]

  POSSIBLE_UNITS = ['oz', 'ml', 'tsp', 'tbsp', 'dash', 'cup', 'unknown']

  # TODO: there's a lot of opportunity to share code here
  def index
    search_term = search_params['search_term']

    if search_term.present? && search_term.size > 0
      @cocktails = Recipe.for_user(current_user).where(category: 'cocktail').where('name ILIKE ?', "%#{search_term}%").order(:name)
    else
      @cocktails = Recipe.for_user(current_user).where(category: 'cocktail').order(:name)
    end
  end

  # SO GROSS that I'm repeating this, but it's late at night
  def available_counts
    search_term = search_params['search_term']

    # force lookup for non-user mapped cocktails
    if search_term.present? && search_term.size > 0
      cocktails = Recipe.for_user(current_user).where(category: 'cocktail').where('name ILIKE ?', "%#{search_term}%").order(:name)
    else
      cocktails = Recipe.for_user(current_user).where(category: 'cocktail').order(:name)
    end

    cocktail_service = CocktailAvailabilityService.new(cocktails, current_user)

    respond_to do |format|
      format.json { render json: { available_counts: cocktail_service.available_counts } }
    end
  end

  def new
    @cocktail = Recipe.new(category: 'cocktail', user_id: current_user.id)
    @reagents = Reagent.for_user(current_user).all.order(:name)
    @form_path = cocktails_path
    @editing = false
    @reagent_categories = ReagentCategory.all.order(:name)
    @possible_units = POSSIBLE_UNITS
  end

  def show
    @stats = {
      made_count: Audit.for_user(current_user).where(recipe: @cocktail).count
    }
    flash.notice = params[:notice] if params[:notice].present?
  end

  def edit
    @form_path = cocktail_path(@cocktail)
    @reagents = Reagent.for_user(current_user).all.order(:name)
    @editing = true
    @reagent_categories = ReagentCategory.all.order(:name)
    @possible_units = POSSIBLE_UNITS
  end

  def pre_make_drink
    cocktail = Recipe.where(id: params[:cocktail_id])

    service = CocktailAvailabilityService.new(cocktail, current_user)
    reagent_options = service.availability_map[params[:cocktail_id].to_i]

    formatted_reagent_options = reagent_options.map do |(amount, bottles)|
      {
        tags: amount.tags.join(', '),
        required: amount.required_volume.to_s,
        bottle_choices: bottles.map do |b|
          {
            id: b.id,
            name: b.name,
            volume_available: b.current_volume.convert_to(amount.unit).format("%.2<value>f %<unit>s", with_conversion_string: false)
          }
        end
      }
    end

    drink_options = {
      name: cocktail.first.name,
      reagent_options: formatted_reagent_options
    }

    respond_to do |format|
      format.json { render json: drink_options }
    end
  end

  def make_drink
    # TODO: it shouldn't be possible to click this button if you don't have the ingredients
    cocktail = Recipe.where(id: params[:cocktail_id])

    service = CocktailAvailabilityService.new(cocktail, current_user)
    reagent_options = service.availability_map[params[:cocktail_id].to_i]

    used_reagents = reagent_options.map do |(amount, bottles)|
      chosen_bottle = bottles.find { |b| params[:bottles][:chosen_id].include?(b.id.to_s) }
      
      chosen_bottle.subtract_usage(amount.required_volume)

      {
        used_model: chosen_bottle,
        used_amount: amount.amount,
        used_unit: amount.unit,
        used_detail: amount.description
      }
    end

    old_count = Audit.for_user(current_user).where(recipe: cocktail.first).count
    create_audit(cocktail.first, used_reagents)

    formatted_used = used_reagents.map do |used|
      used[:used_model].name
    end

    respond_to do |format|
      format.json { render json: { cocktail_name: cocktail.name, reagents_used: formatted_used, made_count: old_count + 1 } }
    end
  end

  def create
    parsed_params = cocktail_params.merge(category: 'cocktail', user_id: current_user.id)

    @cocktail = Recipe.create(parsed_params.slice(:name, :category, :favorite, :user_id))
    # TODO: Figure out how to get errors sent up the chain here

    # TODO: there are errors possible here too
    amounts = create_reagent_amounts(@cocktail, parsed_params[:reagent_amounts]) if @cocktail.present?

    respond_to do |format|
      if @cocktail.present?
        format.json { render json: { redirect_url: "#{cocktail_path(@cocktail)}?notice=#{ERB::Util.url_encode("#{@cocktail.name} was successfully created")}" } }
      else
        format.json { render json: { redirect_url: new_cocktail_path, status: :unprocessable_entity } }
      end
    end
  end

  def update
    parsed_params = cocktail_params.merge(category: 'cocktail', user_id: current_user)

    # wasteful to do this every time, but easier...
    @cocktail.reagent_amounts.destroy_all
    amounts = create_reagent_amounts(@cocktail, parsed_params[:reagent_amounts]) if @cocktail.present?

    respond_to do |format|
      if @cocktail.update(cocktail_params.slice(:name, :category, :favorite))
        format.json { render json: { redirect_url: "#{cocktail_path(@cocktail)}?notice=#{ERB::Util.url_encode("#{@cocktail.name} was successfully updated")}" } }
      else
        format.json { render json: { redirect_url: cocktail_path(@cocktail), status: :unprocessable_entity } }
      end
    end
  end

  def create_reagent_amounts(cocktail, amounts_array)
    amounts_array.map do |raw_amount|
      create_params = {
        recipe: cocktail,
        amount: raw_amount[:reagent_amount],
        unit: raw_amount[:reagent_unit],
        user_id: current_user.id
      }

      existing_tags = raw_amount[:tags].select { |t| t[:new].blank? }.map { |t| t[:tag] }
      existing_category_models = ReagentCategory.where(external_id: existing_tags)

      new_tags = raw_amount[:tags].select { |t| t[:new] }.map { |t| t[:tag] }
      new_tag_models = new_tags.map do |new_t|
        ReagentCategory.find_or_create_by(external_id: new_t) do |model|
          model.name = new_t.titleize
        end
      end

      create_params[:tags] = existing_category_models.pluck(:external_id) + new_tag_models.pluck(:external_id)

      ReagentAmount.create(**create_params)
    end
  end

  def delete
    cocktail = Recipe.for_user(current_user).find_by(id: params['cocktail_id'])
    cocktail.destroy if cocktail.present?

    respond_to do |format|
      format.json { render json: { action: :deleted, deleted_id: cocktail.id, deleted_name: cocktail.name } }
    end
  end

  # TODO: these json only routes should be more consistent and more DRY
  def toggle_favorite
    cocktail = Recipe.for_user(current_user).find_by(id: params['cocktail_id'])
    cocktail.favorite = !cocktail.favorite

    cocktail.save

    respond_to do |format|
      format.json { render json: { action: cocktail.favorite ? :favorited : :unfavorited, favorited_id: cocktail.id } }
    end
  end

  private
    def set_cocktail
      # TODO: handle 404
      @cocktail = Recipe.for_user(current_user).find(params[:id])
    end

    def cocktail_params
      permitted = params
        .require(:cocktail)
          .permit(:name, :favorite, amounts: [[tags: [:tag, :new]], :amount, :unit])

      {}.tap do |final_params|
        final_params[:name] = permitted[:name]
        final_params[:favorite] = permitted[:favorite]
        final_params[:reagent_amounts] = permitted[:amounts].map do |amount|
          {
            reagent_amount: amount[:amount],
            reagent_unit: amount[:unit],
            tags: amount[:tags]
          }
        end
      end
    end

    def search_params
      params.permit(:search_term)
    end

    def create_audit(cocktail, used_reagents)
      audit_info = used_reagents.map do |used|
        {
          reagent_id: used[:used_model].id,
          reagent_name: used[:used_model].name,
          amount_used: used[:used_amount],
          unit_used: used[:used_unit],
          description: used[:used_detail]
        }
      end

      Audit.create!(user_id: current_user.id, recipe: cocktail, info: {reagents: audit_info})
    end
end