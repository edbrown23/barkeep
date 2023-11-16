class DrinkMakingController < ApplicationController
  before_action :authenticate_user!
  before_action :set_cocktails
  
  def show
    service = CocktailAvailabilityService.new(@cocktails, current_user)
    @reagent_options = service.availability_map[@cocktail.id]

    if params[:twist_mode]
      @twist_mode = true
      @substitute_bottles = Reagent.for_user(current_user).real.has_volume.order(:name)
    end
  end

  def update
    # TODO: need to update the availability of reagents in cocktail tables when this is called
    service = CocktailAvailabilityService.new(@cocktails, current_user)
    reagent_options = service.availability_map[@cocktail.id]

    modifier = bottle_params['double'].present? ? 2.0 : 1.0

    @used_reagents = bottle_params[:bottles].to_h.map do |(reagent_amount_id, bottle_info)|
      substituted = bottle_info[:substitute].present?
      subbed_bottle_id = bottle_info[:substitute_bottle]
      original_bottle_id = bottle_info[:bottle]

      bottle_id = substituted ? subbed_bottle_id : original_bottle_id

      chosen_bottle = Reagent.find_by(id: bottle_id)
      next unless chosen_bottle.present?

      amount = ReagentAmount.find_by(id: reagent_amount_id)
      next unless amount.present?

      chosen_bottle.subtract_usage(amount.required_volume.scale(modifier))

      {
        used_model: chosen_bottle,
        used_amount: amount.amount.to_f * modifier,
        used_unit: amount.unit,
        used_detail: amount.description
      }.tap do |used|
        used[:original_tags] = amount.tags if substituted
      end
    end.compact

    @old_count = Audit.for_user(current_user).where(recipe: @cocktail).count
    @old_global_count = Audit.where(recipe: @cocktail).count
    @audit = create_audit(@cocktail, @used_reagents)

    formatted_used = @used_reagents.map do |used|
      used[:used_model].name
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to cocktail_path(@cocktail), notice: "#{@cocktail.name} made!", status: :see_other }
    end
  end

  private

  def create_audit(cocktail, used_reagents)
    audit_info = used_reagents.map do |used|
      info = {
        reagent_id: used[:used_model].id,
        reagent_name: used[:used_model].name,
        amount_used: used[:used_amount],
        unit_used: used[:used_unit],
        description: used[:used_detail]
      }
      if used[:original_tags].present?
        info[:original_tags] = used[:original_tags]
        info[:substituted] = true
      end
      info
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

  def set_cocktails
    @cocktails = Recipe.for_user_or_shared(current_user).where(id: params[:id])
    @cocktail = @cocktails.first
  end

  def bottle_params
    params.require(:drink).permit(:id, :double, bottles: {})
  end
end