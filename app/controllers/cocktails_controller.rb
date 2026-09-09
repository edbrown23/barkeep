class CocktailsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_cocktail, only: [:show]
  before_action :set_owned_cocktail, only: [:edit, :update]

  def index
    search = CocktailSearch.new(current_user, search_params)
    @cocktails = search.cocktails
    @ownership = search.ownership
    @tags_search = search.tags
    @availability = search.availability
    @families = search.families
    @reagent_categories = search.reagent_categories
    @processed_facets = search.facets
    @dead_end = @cocktails.empty? && @tags_search.present?
    if current_user&.admin? && @ownership == 'shared'
      @proposal_cocktails = Recipe.cocktails.where.not(user_id: nil).where('extras @> ?', { proposed_to_be_shared: true }.to_json)
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
    @families = @cocktail.cocktail_families.where(user_id: [nil, current_user&.id])
    @stats = {}
    @favorite = false
    @shopping_lists = []
    @existing_shopping_list_map = {}
    @recent_audits = []
    @user_copies = []
    if user_signed_in?
      @stats[:made_count] = Audit.where(user: current_user, recipe: @cocktail).count
      @favorite = @cocktail.cocktail_families.exists?(user_id: current_user.id, name: Constants::COCKTAIL_FAVORITES_NAME)
      @shopping_lists = ShoppingList.where(user: current_user)
      @existing_shopping_list_map = @cocktail.reagent_amounts.to_h do |amount|
        [amount.id, Reagent.where(user: current_user).with_tags(amount.tags).where.not(shopping_list: nil).pluck(:shopping_list_id)]
      end
      @recent_audits = Audit.where(user: current_user, recipe: @cocktail).order(created_at: :desc).limit(5)
      @user_copies = Recipe.cocktails.where(user: current_user, parent: @cocktail) if @cocktail.shared?
    end
    if @cocktail.shared?
      @stats[:made_globally_count] = Audit.where(recipe: @cocktail).count
      @community_renderable_audits = Audit.where(recipe: @cocktail).where.not(user: current_user).order(created_at: :desc).select { |audit| audit.notes.present? }
    end
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
    @reagents = Reagent.for_user(current_user).real.has_volume.order(:name)
    @form_path = cocktails_path
    @reagent_categories = ReagentCategory.where(external_id: @reagents.pluck(:tags).flatten).order(:name)
    @possible_units = POSSIBLE_UNITS
    flash.alert = params[:alert] if params[:alert].present?
  end

  def propose_to_share
    cocktail = Recipe.cocktails.where(user: current_user).find(cocktail_id)

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
    cocktail = Recipe.cocktails.where(user: current_user).find(cocktail_id)

    raise ActiveRecord::RecordNotFound unless cocktail.ephemeral?

    cocktail.update!(source: '')

    respond_to do |format|
      format.html { redirect_to cocktail_path(cocktail), notice: 'Made this drink permanent! Find it in your cocktail list.' }
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

      embedding = RecipeEmbeddingsService.generate(@cocktail)
      @cocktail.update!(embedding: embedding)

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

    embedding = RecipeEmbeddingsService.generate(@cocktail)
    @cocktail.update!(embedding: embedding)

    respond_to do |format|
      if @cocktail.update(cocktail_params.slice(:name, :category))
        format.json { render json: { redirect_url: "#{cocktail_path(@cocktail)}?notice=#{ERB::Util.url_encode("#{@cocktail.name} was successfully updated")}" } }
      else
        format.json { render json: { redirect_url: cocktail_path(@cocktail), status: :unprocessable_entity } }
      end
    end
  end

  def nearest_neighbors
    @cocktail = Recipe.cocktails.visible_to(current_user).find(cocktail_id)
    @neighbors = @cocktail.nearest_neighbors(:embedding, distance: :inner_product).cocktails.visible_to(current_user).limit(10)
  end

  def add_to_account
    @shared_cocktail = Recipe.cocktails.shared.find(cocktail_id)
    @copied_cocktail = CocktailCopyService.customize(@shared_cocktail, current_user)
    respond_to do |format|
      format.html { redirect_to cocktail_path(@copied_cocktail), notice: 'Your personal copy is ready to customize.', status: :see_other }
      format.turbo_stream
      format.json { render json: { action: 'add_to_account', cocktail_name: @shared_cocktail.name } }
    end
  end

  def promote_to_shared
    return head :forbidden unless current_user.admin?

    cocktail = Recipe.cocktails.where.not(user_id: nil).find(cocktail_id)
    CocktailCopyService.publish(cocktail)
    respond_to do |format|
      format.html { redirect_to cocktails_path(ownership: 'shared'), notice: 'Published shared recipe.', status: :see_other }
      format.json { render json: { action: 'promoted_to_shared' } }
    end
  end

  def create_reagent_amounts(cocktail, amounts_array)
    amounts_array.map do |raw_amount|
      create_params = {
        recipe: cocktail,
        amount: raw_amount[:reagent_amount],
        unit: raw_amount[:reagent_unit],
        user_id: current_user.id,
        optional: raw_amount[:optional]
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

  def destroy
    # Route path parameters cannot be overridden by request query/body values.
    legacy_scope = request.path_parameters[:deletion_scope]
    scope = Recipe.cocktails
    if legacy_scope == 'shared'
      return head :forbidden unless current_user.admin?
      scope = scope.shared
    elsif legacy_scope == 'owned' || !current_user.admin?
      scope = scope.where(user: current_user)
    else
      scope = scope.visible_to(current_user)
    end
    cocktail = scope.find(cocktail_id)
    cocktail.destroy!
    respond_to do |format|
      format.json { render json: { action: 'deleted', deleted_id: cocktail.id, deleted_name: cocktail.name } }
      format.html { redirect_to cocktails_path, notice: "#{cocktail.name} deleted!", status: :see_other }
    end
  end

  def toggle_favorite
    cocktail = Recipe.cocktails.visible_to(current_user).find(cocktail_id)
    favorite_family = CocktailFamily.where(user: current_user).find_or_create_by!(name: Constants::COCKTAIL_FAVORITES_NAME)

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
        format.html { redirect_to cocktail_path(cocktail), notice: "Favorited the #{cocktail.name}!" }
      else
        format.html { redirect_to cocktail_path(cocktail), notice: "Removed favorite from the #{cocktail.name}" }
      end
    end
  end

  private

  def cocktail_id
    path = request.path_parameters
    path[:id] || path[:cocktail_id] || path[:shared_cocktail_id]
  end

  def set_cocktail
    @cocktail = Recipe.cocktails.visible_to(current_user).find(params[:id])
  end

  def set_owned_cocktail
    @cocktail = Recipe.cocktails.where(user: current_user).find(params[:id])
  end

  def cocktail_params
    permitted = params
      .require(:cocktail)
        .permit(:name, :source, amounts: [[tags: [:tag, :new]], :amount, :unit, :optional])

    {}.tap do |final_params|
      final_params[:name] = permitted[:name]
      final_params[:source] = permitted[:source]
      final_params[:reagent_amounts] = permitted[:amounts].map do |amount|
        {
          reagent_amount: amount[:amount],
          reagent_unit: amount[:unit],
          tags: amount[:tags],
          optional: amount[:optional]
        }
      end
    end
  end

  def search_params
    params.permit(:page, :ownership, :commit, :search_term, :makeable, :user_recipes_only, :shared_recipes_only, family_ids: [], search_tags: [])
  end

end
