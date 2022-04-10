class CocktailsController < ApplicationController
  before_action :authenticate_user!

  before_action :set_cocktail, only: [:show, :edit, :update, :destroy]

  # TODO: there's a lot of opportunity to share code here
  def index
    search_term = search_params['search_term']

    if search_term.present? && search_term.size > 0
      @cocktails = Recipe.for_user(current_user).where(category: 'cocktail').where('name ILIKE ?', "%#{search_term}%").order(:id)
    else
      @cocktails = Recipe.for_user(current_user).where(category: 'cocktail').order(:id)
    end
  end

  def new
    @cocktail = Recipe.new(category: 'cocktail', user_id: current_user.id)
    @reagents = Reagent.for_user(current_user).all.order(:name)
    @form_path = cocktails_path
    @editing = false
    @reagent_categories = ReagentCategory.for_user(current_user).all.order(:name)
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
    @reagent_categories = ReagentCategory.for_user(current_user).all.order(:name)
  end

  def make_drink
    cocktail = Recipe.for_user(current_user).find(params[:cocktail_id])

    used_reagents = cocktail.reagent_amounts.map do |amount|
      reagent = amount.reagent

      if amount.reagent_category.present?
        reagent = amount.reagent_category.reagents.first
      end

      # this assumes ounces, which is wrong
      reagent.subtract_ounces(amount.amount)

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
        user_id: current_user.id
      }

      create_params[:reagent] = raw_amount[:reagent_model] if raw_amount[:save_reagent]
      create_params[:reagent_category] = raw_amount[:reagent_category_model] if raw_amount[:save_category]

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
          .permit(:name, :favorite, ingredients: {reagent_id: [], reagent_amount: [], reagent_category_id: [], save_reagent: {}, save_category: {}})

      # everything about this is awful, because it's tied so tightly to how the UI is laid out.
      # I really need to redo the submission side of this has pure javascript, and handle everything
      # there, so that the controller is pure API
      # I'm adding a value at the front that will be dropped by the later `compact`
      parsed_save_reagent_radios = ['true'] + permitted[:ingredients][:save_reagent].values.flatten
      parsed_save_category_radios = ['true'] + permitted[:ingredients][:save_category].values.flatten
      {}.tap do |final_params|
        final_params[:name] = permitted[:name]
        final_params[:favorite] = permitted[:favorite] == "1"
        final_params[:reagent_amounts] = permitted[:ingredients][:reagent_id].map.with_index do |reagent_id, i|
          reagent_model = Reagent.for_user(current_user).find_by(id: reagent_id)
          reagent_amount = permitted[:ingredients][:reagent_amount][i]

          category_model = ReagentCategory.for_user(current_user).find_by(id: permitted[:ingredients][:reagent_category_id][i])

          # this largely allows the compact to skip the values from the hidden form. Again, terrible mixing of
          # view and controller logic
          next if reagent_model.blank? || reagent_amount.blank?

          {
            reagent_model: reagent_model,
            save_reagent: parsed_save_reagent_radios[i] == 'true',
            reagent_amount: reagent_amount,
            reagent_category_model: category_model,
            save_category: parsed_save_category_radios[i] == 'true'
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