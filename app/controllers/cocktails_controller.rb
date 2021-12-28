class CocktailsController < ApplicationController
  before_action :set_cocktail, only: [:show, :edit, :update, :destroy]

  # TODO: there's a lot of opportunity to share code here
  def index
    search_term = search_params['search_term']

    if search_term.present? && search_term.size > 0
      @cocktails = Recipe.where(category: 'cocktail').where('name ILIKE ?', "%#{search_term}%").order(:id)
    else
      @cocktails = Recipe.where(category: 'cocktail').order(:id)
    end
  end

  def new
    @cocktail = Recipe.new(category: 'cocktail')
    @reagents = Reagent.all
    @form_path = cocktails_path
  end

  def show
  end

  def edit
    @form_path = cocktail_path(@cocktail)
  end

  def create
    parsed_params = cocktail_params.merge(category: 'cocktail')

    @cocktail = Recipe.create(parsed_params.slice(:name, :category))
    # TODO: Figure out how to get errors sent up the chain here

    # TODO: there are errors possible here too
    amounts = create_reagent_amounts(@cocktail, parsed_params[:reagent_amounts]) if @cocktail.present?

    respond_to do |format|
      if @cocktail.present?
        # TODO: handle the notice
        format.html { redirect_to cocktail_path(@cocktail), notice: "#{@cocktail.name} was successfully created" }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @cocktail.update(cocktail_params)
        # TODO: handle the notice
        format.html { redirect_to cocktail_path(@cocktail), notice: "#{@cocktail.name} was successfully updated" }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def create_reagent_amounts(cocktail, amounts_array)
    amounts_array.map do |raw_amount|
      ReagentAmount.create(
        recipe: cocktail,
        amount: raw_amount[:reagent_amount],
        reagent: raw_amount[:reagent_model]
      )
    end
  end

  # figure out how to refresh the page automatically when you do this
  def delete
    cocktail = Recipe.find_by(id: params['cocktail_id'])
    cocktail.destroy if cocktail.present?
  end

  private
    def set_cocktail
      # TODO: handle 404
      @cocktail = Recipe.find(params[:id])
    end

    def cocktail_params
      # I bet we could pull this from the model, that would be cool
      permitted = params
        .require(:recipe)
          .permit(:name, ingredients: {reagent_id: [], reagent_amount: []})

      {}.tap do |final_params|
        final_params[:name] = permitted[:name]
        final_params[:reagent_amounts] = permitted[:ingredients][:reagent_id].map.with_index do |reagent_id, i|
          reagent_model = Reagent.find_by(id: reagent_id)
          reagent_amount = permitted[:ingredients][:reagent_amount][i]
          next if reagent_model.blank? || reagent_amount.blank?

          {
            reagent_model: reagent_model,
            reagent_amount: reagent_amount
          }
        end.compact
      end
    end

    def search_params
      params.permit(:search_term)
    end
end