# TODO: this controller shares a frustrating amount of logic with the authed cocktails controller
class SharedCocktailsController < ApplicationController
  before_action :authenticate_user!, only: [:add_to_account]

  before_action :set_cocktail, only: [:show, :destroy]

  def index
    search_term = search_params['search_term']
    @tags_search = search_params['search_tags']
    makeable_enabled = search_params['makeable'].present? && search_params['makeable'] == 'on'

    initial_scope = Recipe.for_user(nil).where(category: 'cocktail')

    # force lookup for non-user mapped cocktails
    if search_term.present? && search_term.size > 0
      initial_scope = initial_scope.where('name ILIKE ?', "%#{search_term}%")
    end

    if @tags_search.present? && @tags_search.size > 0
      initial_scope = initial_scope.by_tag(*Array.wrap(@tags_search))
    end

    @availability = CocktailAvailabilityService.new(initial_scope, current_user)
    if makeable_enabled && user_signed_in?
      initial_scope = initial_scope.where(id: @availability.makeable_ids)
    end

    @reagent_categories = ReagentCategory.where(external_id: initial_scope.flat_map(&:tags)).order(:name)
    @cocktails = initial_scope.order(:name).page(params[:page])
    @dead_end = @cocktails.count <= 0 && @tags_search.present? ? true : false

    if user_signed_in? && current_user.admin?
      @proposal_cocktails = Recipe.where(category: 'cocktail').where('extras @> ?', { proposed_to_be_shared: true }.to_json)
    end

    # WIP faceting logic below here (pretty sure there's some sql injection in all this)
    raw_sql = "select word, ndoc from ts_stat($$ #{initial_scope.select(:searchable).to_sql} $$) order by ndoc desc;"
    if initial_scope.pluck(:id).count > 0
      raw_facets = ActiveRecord::Base.connection.execute(raw_sql)
      @processed_facets = raw_facets.entries.index_by { |f| f['word'] }
    else
      @processed_facets = {}
    end
  end

  def show
    @stats = {
      made_count: Audit.for_user(current_user).where(recipe: @cocktail).count,
      made_globally_count: Audit.where(recipe: @cocktail).count
    }
    @favorite = @cocktail.cocktail_families.include?(CocktailFamily.users_favorites(current_user))

    @users_renderable_audits = Audit.for_user(current_user).where(recipe: @cocktail).select { |audit| audit.notes.present? }
    @community_renderable_audits = Audit.where.not(user: current_user).where(recipe: @cocktail).select { |audit| audit.notes.present? }
    @user_copies = Recipe.for_user(current_user).where(parent: @cocktail)
  end

  def destroy
    @cocktail.destroy if @cocktail.present?

    respond_to do |format|
      format.html { redirect_to '/shared_cocktails', alert: "#{@cocktail.name} deleted!" }
    end
  end

  def add_to_account
    shared_cocktail = Recipe.find(params[:shared_cocktail_id])

    Recipe.transaction do
      copied_cocktail = shared_cocktail.dup
      copied_cocktail.user_id = current_user.id
      copied_cocktail.parent = shared_cocktail
      copied_cocktail.clear_ingredients
      copied_cocktail.save!

      shared_cocktail.reagent_amounts.each do |shared_amount|
        copied_amount = shared_amount.dup
        copied_amount.recipe_id = copied_cocktail.id
        copied_amount.user_id = current_user.id
        
        copied_amount.save!

        copied_cocktail << copied_amount.convert_to_blob
      end

      copied_cocktail.save!
    end

    respond_to do |format|
      format.json { render json: { action: 'add_to_account', cocktail_name: shared_cocktail.name.html_safe } }
    end
  end

  def promote_to_shared
    cocktail = Recipe.find(params[:shared_cocktail_id])

    Recipe.transaction do
      cocktail.proposed_to_be_shared = false
      cocktail.proposer_user_id = nil
      cocktail.save!

      copied_cocktail = cocktail.dup
      copied_cocktail.user_id = nil
      copied_cocktail.proposed_to_be_shared = false
      copied_cocktail.parent_id = nil
      copied_cocktail.clear_ingredients
      copied_cocktail.save!

      cocktail.reagent_amounts.each do |shared_amount|
        copied_amount = shared_amount.dup
        copied_amount.recipe_id = copied_cocktail.id
        copied_amount.user_id = nil

        copied_amount.save!

        copied_cocktail << copied_amount.convert_to_blob
      end
      copied_cocktail.save!
    end

    respond_to do |format|
      format.html { redirect_to action: 'index' }
      format.json { render json: { action: 'promoted_to_shared' } }
    end
  end

  private

  def set_cocktail
    @cocktail = Recipe.find(params[:id])
  end

  def search_params
    params.permit(:search_term, :makeable, search_tags: [])
  end
end