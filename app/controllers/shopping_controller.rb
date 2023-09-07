class ShoppingController < ApplicationController
  before_action :authenticate_user!

  def index
    shared_cocktails = CocktailAvailabilityService.new(Recipe.for_user(nil).where(category: 'cocktail'), current_user)
    user_cocktails = CocktailAvailabilityService.new(Recipe.for_user(current_user).where(category: 'cocktail'), current_user)
    @counts = shared_cocktails.available_counts.merge(user_cocktails.available_counts)
    
    one_off_cocktails = @counts.select { |_, count| count[:required] - count[:available] == 1 }
    @one_off_cocktails = Recipe.where(id: one_off_cocktails.keys).index_by(&:id)

    @availability = one_off_cocktails

    @inverted_availability = one_off_cocktails.reduce({}) do |memo, (cid, avail)|
      memo[avail[:missing_tags]] ||= []
      memo[avail[:missing_tags]] << @one_off_cocktails[cid]
      memo
    end

    @low_bottles = Reagent.for_user(current_user).select do |bottle|
      (bottle.current_volume_value / bottle.max_volume_value) <= 0.1
    end

    @shopping_lists = ShoppingList.for_user(current_user)
  end

  def show
    @shopping_list = ShoppingList.for_user(current_user).find(params[:id])
    @bottles = Reagent.for_user(current_user).where(shopping_list: @shopping_list)

    cocktails_without_list = CocktailAvailabilityService.new(Recipe.for_user_or_shared(current_user), current_user)
    @availability = CocktailAvailabilityService.new(Recipe.for_user_or_shared(current_user), current_user, @shopping_list)
    @shopping_list_cocktails = Recipe.for_user_or_shared(current_user).where(id: @availability.makeable_ids - cocktails_without_list.makeable_ids).page(params[:page])
  end

  def edit
    @shopping_list = ShoppingList.for_user(current_user).find(params[:id])
  end

  def update
    # use a before_action dummy
    @shopping_list = ShoppingList.for_user(current_user).find(params[:shopping_id])

    @shopping_list.update!(update_params)
    respond_to do |format|
      format.html { redirect_to shopping_path(@shopping_list) }
    end
  end

  def new
    @shopping_list = ShoppingList.new
  end

  def create
    count = ShoppingList.for_user(current_user).count
    @new_list = ShoppingList.create!(name: "Shopping List #{count + 1}", user: current_user)
    
    respond_to do |format|
      format.turbo_stream
    end
  end

  def destroy
    @shopping_list = ShoppingList.for_user(current_user).find(params[:id])
    @shopping_list.destroy!
    
    respond_to do |format|
      format.html { redirect_to shopping_index_path, notice: "#{@shopping_list.name} deleted" }
    end
  end

  # I want this to refer to some sort of confirmation screen where you input bottle info
  def purchase
    @shopping_list = ShoppingList.for_user(current_user).find(params[:shopping_id])
    purchased_bottles = Reagent.for_user(current_user).where(id: purchase_params[:bottle_ids])

    Reagent.transaction do
      purchased_bottles.each do |bottle|
        bottle.update!(shopping_list: nil)
      end

      @shopping_list.destroy!
    end

    respond_to do |format|
      format.html { redirect_to shopping_index_path, notice: "Purchased #{purchased_bottles.count} from #{@shopping_list.name}. List deleted!"}
    end
  end

  def add_to_list
    parsed_params = add_to_list_params
    @maybe_lists = ShoppingList.for_user(current_user).where(id: parsed_params[:shopping_list_id]).to_a

    @maybe_new_lists = parsed_params[:shopping_list_id].reject { |id| (@maybe_lists.pluck(:id).map(&:to_s) + ['']).include?(id) }
    if @maybe_new_lists.present?
      @maybe_new_lists.each do |new_list|
        @maybe_lists << ShoppingList.create!(
          name: new_list.titleize,
          user: current_user
        )
      end
    end

    if @maybe_lists.present?
      placeholder_id = parsed_params[:bottle_tags]

      @maybe_lists.each do |list|
        existing_placeholders_count = Reagent.for_user(current_user).where('external_id ILIKE ?', "%#{placeholder_id}%").count
        final_id = "#{placeholder_id}_#{existing_placeholders_count + 1}"

        @placeholder = Reagent.create!(
          name: final_id.titleize,
          external_id: final_id,
          user: current_user,
          max_volume_unit: 'ml',
          max_volume_value: 750,
          current_volume_unit: 'ml',
          current_volume_value: 750,
          tags: parsed_params[:bottle_tags].split(','),
          shopping_list: list
        )
      end
    end

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def create_params
    params.require(:shopping_list).permit(:name)
  end

  def add_to_list_params
    params.require(:list_update).permit(:bottle_tags, shopping_list_id: [])
  end

  def purchase_params
    params.require(:shopping).permit(bottle_ids: [])
  end

  def update_params
    params.require(:shopping_list).permit(:name)
  end
end