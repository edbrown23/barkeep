class CocktailsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_cocktail, only: [:show, :edit, :update, :destroy]

  POSSIBLE_UNITS = ['oz', 'ml', 'tsp', 'tbsp', 'dash', 'cup', 'unknown']

  # TODO: there's a lot of opportunity to share code here
  def index
    search_term = search_params['search_term']

    if search_term.present? && search_term.size > 0
      @cocktails = Recipe.for_user(current_user).where(category: 'cocktail').where('name ILIKE ?', "%#{search_term}%").order(:id)
    else
      @cocktails = Recipe.for_user(current_user).where(category: 'cocktail').order(:id)
    end
  end

  # SO GROSS that I'm repeating this, but it's late at night
  def available_counts
    search_term = search_params['search_term']

    # force lookup for non-user mapped cocktails
    if search_term.present? && search_term.size > 0
      cocktails = Recipe.for_user(current_user).where(category: 'cocktail').where('name ILIKE ?', "%#{search_term}%").order(:id)
    else
      cocktails = Recipe.for_user(current_user).where(category: 'cocktail').order(:id)
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
  end

  def edit
    @form_path = cocktail_path(@cocktail)
    @reagents = Reagent.for_user(current_user).all.order(:name)
    @editing = true
    @reagent_categories = ReagentCategory.all.order(:name)
    @possible_units = POSSIBLE_UNITS
  end

  def make_drink
    # TODO: it shouldn't be possible to click this button if you don't have the ingredients
    cocktail = Recipe.find(params[:cocktail_id])

    used_reagents = cocktail.reagent_amounts.map do |amount|
      # TODO: the user needs to be able to select from all their options here
      reagent = Reagent.for_user(current_user).with_tags(amount.tags).first

      # this assumes ounces, which is wrong
      reagent.subtract_usage(amount.required_volume)

      {
        used_model: reagent,
        used_amount: amount.amount,
        used_unit: amount.unit,
        used_detail: amount.description
      }
    end

    old_count = Audit.for_user(current_user).where(recipe: cocktail).count
    create_audit(cocktail, used_reagents)

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
        # TODO: handle the notice
        format.html { redirect_to cocktail_path(@cocktail), notice: "#{@cocktail.name} was successfully created" }
      else
        format.html { render :new, status: :unprocessable_entity }
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
        # TODO: handle the notice
        format.html { redirect_to cocktail_path(@cocktail), notice: "#{@cocktail.name} was successfully updated" }
      else
        format.html { render :new, status: :unprocessable_entity }
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

      if raw_amount[:new_category_external_id].present?
        new_tag = raw_amount[:new_category_external_id]
        category_model = ReagentCategory.find_or_create_by(external_id: new_tag) do |cat_mod|
          cat_mod.name = new_tag.titleize
        end
      else
        category_model = raw_amount[:reagent_category_model]
      end
      create_params[:tags] = [category_model.external_id]

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
      # I bet we could pull this from the model, that would be cool
      permitted = params
        .require(:recipe)
          .permit(:name, :favorite, ingredients: {reagent_amount: [], reagent_unit: [], reagent_category_id: [], new_category: []})

      # everything about this is awful, because it's tied so tightly to how the UI is laid out.
      # I really need to redo the submission side of this has pure javascript, and handle everything
      # there, so that the controller is pure API
      # I'm adding a value at the front that will be dropped by the later `compact`
      {}.tap do |final_params|
        final_params[:name] = permitted[:name]
        final_params[:favorite] = permitted[:favorite] == "1"
        final_params[:reagent_amounts] = permitted[:ingredients][:reagent_category_id].map.with_index do |reagent_category_id, i|
          category_model = ReagentCategory.find_by(id: reagent_category_id)
          new_category_external_id = Lib.to_external_id(permitted[:ingredients][:new_category][i])
          reagent_amount = permitted[:ingredients][:reagent_amount][i]
          reagent_unit = permitted[:ingredients][:reagent_unit][i]

          # this largely allows the compact to skip the values from the hidden form. Again, terrible mixing of
          # view and controller logic
          next if reagent_amount.blank?

          {
            reagent_amount: reagent_amount,
            reagent_unit: reagent_unit,
            reagent_category_model: category_model,
            new_category_external_id: new_category_external_id
          }
        end.compact
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