# TODO: this controller shares a frustrating amount of logic with the authed cocktails controller
class SharedCocktailsController < ApplicationController
  before_action :authenticate_user!, only: [:add_to_account]

  before_action :set_cocktail, only: [:show, :destroy]

  def index
    search_term = search_params['search_term']
    tags_search = search_params['search_tags']

    initial_scope = Recipe.for_user(nil).where(category: 'cocktail')

    # force lookup for non-user mapped cocktails
    if search_term.present? && search_term.size > 0
      initial_scope = initial_scope.where('name ILIKE ?', "%#{search_term}%")
    end

    if tags_search.present? && tags_search.size > 0
      amounts = ReagentAmount.for_user(nil).with_tags(Array.wrap(tags_search))
      initial_scope = initial_scope.where(id: amounts.pluck(:recipe_id))
    end

    @reagent_categories = ReagentCategory.all.order(:name)
    @cocktails = initial_scope.order(:name)

    if user_signed_in? && current_user.admin?
      @proposal_cocktails = Recipe.where(category: 'cocktail').where('extras @> ?', { proposed_to_be_shared: true }.to_json)
    end
  end

  # I want this exact function in my cocktails_controller too
  def available_counts
    search_term = search_params['search_term']
    tags_search = search_params['search_tags']

    initial_scope = Recipe.for_user(nil).where(category: 'cocktail')

    if search_term.present? && search_term.size > 0
      initial_scope = initial_scope.where('name ILIKE ?', "%#{search_term}%")
    end

    if tags_search.present? && tags_search.size > 0
      amounts = ReagentAmount.for_user(nil).with_tags(Array.wrap(tags_search))
      initial_scope = initial_scope.where(id: amounts.pluck(:recipe_id))
    end

    cocktail_service = CocktailAvailabilityService.new(initial_scope, current_user)

    respond_to do |format|
      format.json { render json: { available_counts: cocktail_service.available_counts } }
    end
  end

  def show
    @stats = {
      made_count: Audit.for_user(current_user).where(recipe: @cocktail).count,
      made_globally_count: Audit.where(recipe: @cocktail).count
    }

    @users_renderable_audits = Audit.for_user(current_user).where(recipe: @cocktail).select { |audit| audit.notes.present? }
    @community_renderable_audits = Audit.where.not(user: current_user).where(recipe: @cocktail).select { |audit| audit.notes.present? }
  end

  def destroy
    @cocktail.destroy if @cocktail.present?

    respond_to do |format|
      format.html { redirect_to '/shared_cocktails', alert: "#{@cocktail.name} deleted!" }
    end
  end

  def add_to_account
    # TODO it'd be cool if copied recipes stayed associated with their parent
    shared_cocktail = Recipe.find(params[:shared_cocktail_id])

    Recipe.transaction do
      copied_cocktail = shared_cocktail.dup
      copied_cocktail.user_id = current_user.id
      copied_cocktail.parent = shared_cocktail
      copied_cocktail.save!

      shared_cocktail.reagent_amounts.each do |shared_amount|
        copied_amount = shared_amount.dup
        copied_amount.recipe_id = copied_cocktail.id
        copied_amount.user_id = current_user.id
        
        copied_amount.save!
      end
    end

    respond_to do |format|
      format.json { render json: { cocktail_name: shared_cocktail.name } }
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
      copied_cocktail.save!

      cocktail.reagent_amounts.each do |shared_amount|
        copied_amount = shared_amount.dup
        copied_amount.recipe_id = copied_cocktail.id
        copied_amount.user_id = nil
        
        copied_amount.save!
      end
    end

    respond_to do |format|
      format.html { redirect_to action: 'index' }
    end
  end

  private

  def set_cocktail
    @cocktail = Recipe.find(params[:id])
  end

  def search_params
    params.permit(:search_term, search_tags: [])
  end
end