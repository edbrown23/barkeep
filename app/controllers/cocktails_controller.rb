class CocktailsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_cocktail, only: [:show, :edit, :update, :destroy]

  # TODO: this code is entirely copied between the shared controller and this one :(
  def index
    search_term = search_params['search_term']
    @tags_search = search_params['search_tags']
    makeable_enabled = search_params['makeable'].present? && search_params['makeable'] == 'on'
    user_recipes_only_enabled = search_params['user_recipes_only'].present? && search_params['user_recipes_only'] == 'on'
    shared_recipes_only_enabled = search_params['shared_recipes_only'].present? && search_params['shared_recipes_only'] == 'on'

    family_ids = search_params['family_ids']

    initial_scope = Recipe
      .for_user_or_shared(current_user)
      .where(category: 'cocktail')
      .where('source != ALL(?::varchar[])', '{drink_builder}')

    if family_ids.present?
      initial_scope = initial_scope.joins(:cocktail_families).where(cocktail_families: { id: family_ids })
    end

    initial_scope = initial_scope.for_user(current_user) if user_recipes_only_enabled
    initial_scope = initial_scope.for_user(nil) if shared_recipes_only_enabled

    if search_term.present? && search_term.size > 0
      initial_scope = initial_scope.where('name ILIKE ?', "%#{search_term}%")
    end

    if @tags_search.present? && @tags_search.size > 0
      initial_scope = initial_scope.by_tag(*Array.wrap(@tags_search))
    end

    @availability = CocktailAvailabilityService.new(initial_scope, current_user)
    if makeable_enabled
      initial_scope = initial_scope.where(id: @availability.makeable_ids)
    end

    # TODO: this shows you all your favorites from among those currently visible.
    #       however, it won't help you narrow down from a large set of favorites
    #       to a smaller set via multiple families. Basically this is an OR query
    #       and I need an AND. favorites AND liquor forward, etc
    @families = CocktailFamily.for_user(current_user).joins(:recipes).where(recipes: initial_scope).uniq

    # TODO: pretty sure the todo below this one is false now. Comments...
    # TODO: once tags are hoisted up to recipes this selector should only show available things
    @reagent_categories = ReagentCategory.where(external_id: initial_scope.flat_map(&:tags)).order(:name)
    @cocktails = initial_scope.reorder(:name).page(params[:page])
    @dead_end = @cocktails.count <= 0 && @tags_search.present? ? true : false

    raw_sql = "select word, ndoc from ts_stat($$ #{initial_scope.select(:searchable).to_sql} $$) order by ndoc desc;"
    if initial_scope.pluck(:id).count > 0
      raw_facets = ActiveRecord::Base.connection.execute(raw_sql)
      @processed_facets = raw_facets.entries.index_by { |f| f['word'] }
    else
      @processed_facets = {}
    end
  end

  def new
    @cocktail = Recipe.new(category: 'cocktail', user_id: current_user.id)
    @reagents = Reagent.for_user(current_user).all.order(:name)
    @form_path = cocktails_path
    @editing = false
    @reagent_categories = ReagentCategory.all.order(:name)
    @possible_units = POSSIBLE_UNITS
    flash.alert = params[:alert] if params[:alert].present?
  end

  def show
    @stats = {
      made_count: Audit.for_user(current_user).where(recipe: @cocktail).count,
      made_globally_count: Audit.where(recipe: @cocktail).count
    }
    @favorite = @cocktail.cocktail_families.include?(CocktailFamily.users_favorites(current_user))

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
    @reagent_categories = ReagentCategory.where(external_id: Reagent.for_user(current_user).pluck(:tags).flatten).order(:name)
    @possible_units = POSSIBLE_UNITS
    flash.alert = params[:alert] if params[:alert].present?
  end

  def propose_to_share
    cocktail = Recipe.find(params[:cocktail_id])

    cocktail.proposed_to_be_shared = true
    cocktail.proposer_user_id = current_user.id
    cocktail.save!

    respond_to do |format|
      format.html { redirect_to cocktail_path(cocktail), notice: 'Submitted for sharing review!' }
      format.turbo_stream
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
      @cocktail = Recipe.create!(parsed_params.slice(:name, :category, :user_id, :source))
      # TODO: Figure out how to get errors sent up the chain here

      # TODO: there are errors possible here too
      amounts = create_reagent_amounts(@cocktail, parsed_params[:reagent_amounts]) if @cocktail.present?
      amounts.each do |a|
        @cocktail << a.convert_to_blob
      end
      @cocktail.save!

      raise ActiveRecord::Rollback unless amounts.size > 0
    end

    respond_to do |format|
      if @cocktail.present? && @cocktail.id.present?
        format.json { render json: { cocktail_id: @cocktail.id, redirect_url: "#{cocktail_path(@cocktail)}?notice=#{ERB::Util.url_encode("#{@cocktail.name} was successfully created")}" } }
      else
        error_string = ERB::Util.url_encode("#{@cocktail.name} couldn't be created. Did you add any ingredients?")
        format.json { render json: { cocktail_id: @cocktail.id, redirect_url: "#{new_cocktail_path}?alert=#{error_string}", error_string: error_string }, status: :unprocessable_entity }
      end
    end
  end

  def update
    parsed_params = cocktail_params.merge(category: 'cocktail', user_id: current_user)

    # wasteful to do this every time, but easier...
    @cocktail.reagent_amounts.destroy_all
    amounts = create_reagent_amounts(@cocktail, parsed_params[:reagent_amounts]) if @cocktail.present?
    @cocktail.clear_ingredients
    amounts.each do |a|
      @cocktail << a.convert_to_blob 
    end

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

  def toggle_favorite
    cocktail = Recipe.find_by(id: params['cocktail_id'])
    favorite_family = CocktailFamily.users_favorites(current_user)

    if cocktail.cocktail_families.include?(favorite_family)
      joiner = CocktailFamilyJoiner.find_by(recipe: cocktail, cocktail_family: favorite_family)
      favorited = false
      joiner.destroy!
    else
      cocktail.cocktail_families << favorite_family
      favorited = true
    end

    cocktail.save

    respond_to do |format|
      if favorited
        format.html { redirect_to cocktail_path(cocktail), notice: "Favorited the #{cocktail.name.html_safe}!" }
      else
        format.html { redirect_to cocktail_path(cocktail), notice: "Removed favorite from the #{cocktail.name.html_safe}" }
      end
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
    params.permit(:commit, :search_term, :makeable, :user_recipes_only, :shared_recipes_only, family_ids: [], search_tags: [])
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