class CocktailsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_cocktail, only: [:show, :edit, :update, :destroy]

  # TODO: this code is entirely copied between the shared controller and this one :(
  def index
    search_term = search_params['search_term']
    tags_search = search_params['search_tags']

    initial_scope = Recipe
      .for_user(current_user)
      .where(category: 'cocktail')
      .where('source != ALL(?::varchar[])', '{drink_builder}')

    if search_term.present? && search_term.size > 0
      initial_scope = initial_scope.where('name ILIKE ?', "%#{search_term}%")
    end

    if tags_search.present? && tags_search.size > 0
      amounts = ReagentAmount.for_user(current_user).with_tags(Array.wrap(tags_search))
      initial_scope = initial_scope.where(id: amounts.pluck(:recipe_id))
    end

    @reagent_categories = ReagentCategory.all.order(:name)
    @cocktails = initial_scope.order(:name)
  end

  # SO GROSS that I'm repeating this, but it's late at night
  def available_counts
    search_term = search_params['search_term']
    tags_search = search_params['search_tags']

    initial_scope = Recipe.for_user(current_user).where(category: 'cocktail')

    if search_term.present? && search_term.size > 0
      initial_scope = initial_scope.where('name ILIKE ?', "%#{search_term}%")
    end

    if tags_search.present? && tags_search.size > 0
      amounts = ReagentAmount.for_user(current_user).with_tags(Array.wrap(tags_search))
      initial_scope = initial_scope.where(id: amounts.pluck(:recipe_id))
    end

    cocktail_service = CocktailAvailabilityService.new(initial_scope, current_user)

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
      made_count: Audit.for_user(current_user).where(recipe: @cocktail).count,
      made_globally_count: Audit.where(recipe: @cocktail).count
    }

    @renderable_audits = Audit.for_user(current_user).where(recipe: @cocktail).select { |audit| audit.notes.present? }
    flash.notice = params[:notice] if params[:notice].present?
  end

  def edit
    @form_path = cocktail_path(@cocktail)
    @reagents = Reagent.for_user(current_user).all.order(:name)
    @editing = true
    @reagent_categories = ReagentCategory.all.order(:name)
    @possible_units = POSSIBLE_UNITS
  end

  def drink_builder
    @cocktail = Recipe.new(category: 'cocktail', user_id: current_user.id)
    @reagents = Reagent.for_user(current_user).all.order(:name)
    @form_path = cocktails_path
    @reagent_categories = ReagentCategory.where(external_id: Reagent.for_user(current_user).pluck(&:tags).flatten).order(:name)
    @possible_units = POSSIBLE_UNITS
  end

  # I'm using these routes for shared cocktails and user cocktails, which seems wrong
  def pre_make_drink
    cocktail = Recipe.where(id: params[:cocktail_id])

    service = CocktailAvailabilityService.new(cocktail, current_user)
    reagent_options = service.availability_map[params[:cocktail_id].to_i]

    formatted_reagent_options = reagent_options.map do |(amount, bottles)|
      {
        tags: amount.tags.join(', '),
        required: amount.required_volume.to_s,
        bottle_choices: bottles.map do |b|
          current = b.current_volume
          {
            id: b.id,
            name: b.name,
            volume_available: current.convert_to(amount.unit).format("%.2<value>f %<unit>s", with_conversion_string: false),
            enough: current >= amount.required_volume
          }
        end
      }
    end

    drink_options = {
      name: cocktail.first.name,
      reagent_options: formatted_reagent_options,
      action: 'pre_make_drink'
    }

    # TODO: do something about modals that users don't have ingredients for
    respond_to do |format|
      format.json { render json: drink_options }
    end
  end

  def make_drink
    # TODO: need to update the availability of reagents in cocktail tables when this is called
    cocktail = Recipe.where(id: params[:cocktail_id])

    service = CocktailAvailabilityService.new(cocktail, current_user)
    reagent_options = service.availability_map[params[:cocktail_id].to_i]

    modifier = params['double'].present? ? 2.0 : 1.0

    used_reagents = reagent_options.map do |(amount, bottles)|
      chosen_bottle = bottles.find { |b| params[:bottles][:chosen_id].include?(b.id.to_s) }
      next unless chosen_bottle.present?
      
      chosen_bottle.subtract_usage(amount.required_volume.scale(modifier))

      {
        used_model: chosen_bottle,
        used_amount: amount.amount * modifier,
        used_unit: amount.unit,
        used_detail: amount.description
      }
    end.compact

    old_count = Audit.for_user(current_user).where(recipe: cocktail.first).count
    old_global_count = Audit.where(recipe: cocktail.first).count
    create_audit(cocktail.first, used_reagents)

    formatted_used = used_reagents.map do |used|
      used[:used_model].name
    end

    respond_to do |format|
      format.json { render json: { action: 'make_drink', cocktail_name: cocktail.name, reagents_used: formatted_used, made_count: old_count + 1, made_globally_count: old_global_count + 1 } }
    end
  end

  def propose_to_share
    cocktail = Recipe.find(params[:cocktail_id])

    cocktail.proposed_to_be_shared = true
    cocktail.proposer_user_id = current_user.id
    cocktail.save!

    respond_to do |format|
      format.json { render json: { action: 'propose_to_share' } }
    end
  end

  def make_permanent
    cocktail = Recipe.find(params[:cocktail_id])

    cocktail.update!(source: '')

    respond_to do |format|
      format.html { redirect_to cocktail_path(cocktail), notice: 'Made this drink permanent! Check it our in Your Cocktail List' }
      format.json { render json: { action: 'make_permanent' } }
    end
  end

  def create
    parsed_params = cocktail_params.merge(category: 'cocktail', user_id: current_user.id)

    Recipe.transaction do
      @cocktail = Recipe.create!(parsed_params.slice(:name, :category, :favorite, :user_id, :source))
      # TODO: Figure out how to get errors sent up the chain here

      # TODO: there are errors possible here too
      amounts = create_reagent_amounts(@cocktail, parsed_params[:reagent_amounts]) if @cocktail.present?
    end

    respond_to do |format|
      if @cocktail.present? && @cocktail.id.present?
        format.json { render json: { cocktail_id: @cocktail.id, redirect_url: "#{cocktail_path(@cocktail)}?notice=#{ERB::Util.url_encode("#{@cocktail.name} was successfully created")}" } }
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

      ReagentAmount.create!(**create_params)
    end
  end

  def delete
    cocktail = Recipe.for_user(current_user).find_by(id: params['cocktail_id'])
    cocktail.destroy if cocktail.present?

    respond_to do |format|
      format.json { render json: { action: :deleted, deleted_id: cocktail.id, deleted_name: cocktail.name } }
      format.html { redirect_to '/cocktails', alert: "#{cocktail.name.html_safe} deleted!" }
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
        .permit(:name, :favorite, :source, amounts: [[tags: [:tag, :new]], :amount, :unit])

    {}.tap do |final_params|
      final_params[:name] = permitted[:name]
      final_params[:favorite] = permitted[:favorite]
      final_params[:source] = permitted[:source]
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
    params.permit(:search_term, search_tags: [])
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

    Audit.create!(
      user_id: current_user.id,
      recipe: cocktail,
      info: {
        cocktail_name: cocktail.name,
        ephemeral_recipe: cocktail.source == 'drink_builder',
        reagents: audit_info
      }
    )
  end
end