# TODO: this controller shares a frustrating amount of logic with the authed cocktails controller
class SharedCocktailsController < ApplicationController
  before_action :authenticate_user!, only: [:add_to_account]

  before_action :set_cocktail, only: [:show]

  def index
    search_term = search_params['search_term']

    # force lookup for non-user mapped cocktails
    if search_term.present? && search_term.size > 0
      @cocktails = Recipe.for_user(nil).where(category: 'cocktail').where('name ILIKE ?', "%#{search_term}%").order(:id)
    else
      @cocktails = Recipe.for_user(nil).where(category: 'cocktail').order(:id)
    end
  end

  # I want this exact function in my cocktails_controller too
  def available_counts
    search_term = search_params['search_term']

    # force lookup for non-user mapped cocktails
    if search_term.present? && search_term.size > 0
      cocktails = Recipe.for_user(nil).where(category: 'cocktail').where('name ILIKE ?', "%#{search_term}%").order(:id)
    else
      cocktails = Recipe.for_user(nil).where(category: 'cocktail').order(:id)
    end

    cocktail_service = CocktailAvailabilityService.new(cocktails, current_user)

    respond_to do |format|
      format.json { render json: { available_counts: cocktail_service.available_counts } }
    end
  end

  def show
    @stats = {
      made_count: Audit.for_user(current_user).where(recipe: @cocktail).count
    }
  end

  def add_to_account
    # TODO it'd be cool if copied recipes stayed associated with their parent
    shared_cocktail = Recipe.find(params[:shared_cocktail_id])

    Recipe.transaction do
      copied_cocktail = shared_cocktail.dup
      copied_cocktail.user_id = current_user.id
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

  private

  def set_cocktail
    @cocktail = Recipe.find(params[:id])
  end

  def search_params
    params.permit(:search_term)
  end
end