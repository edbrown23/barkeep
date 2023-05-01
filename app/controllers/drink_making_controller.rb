class DrinkMakingController < ApplicationController
  before_action :authenticate_user!
  before_action :set_cocktails
  
  def show
    service = CocktailAvailabilityService.new(@cocktails, current_user)
    @reagent_options = service.availability_map[@cocktail.id]
  end

  def update
    # TODO: need to update the availability of reagents in cocktail tables when this is called
    service = CocktailAvailabilityService.new(@cocktails, current_user)
    reagent_options = service.availability_map[@cocktail.id]

    modifier = params['double'].present? ? 2.0 : 1.0

    @used_reagents = reagent_options.map do |(amount, bottles)|
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

    @old_count = Audit.for_user(current_user).where(recipe: @cocktail).count
    @old_global_count = Audit.where(recipe: @cocktail).count
    create_audit(@cocktail, @used_reagents)

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

  def set_cocktails
    @cocktails = Recipe.for_user_or_shared(current_user).where(id: params[:id])
    @cocktail = @cocktails.first
  end
end