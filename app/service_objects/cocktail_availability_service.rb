class CocktailAvailabilityService
  attr_reader :cocktails, :reagents_for_user, :availability_map

  def initialize(cocktails, current_user)
    @cocktails = cocktails
    @current_user = current_user
    @reagents_for_user = preload_reagents_for_user
    @availability_map = setup_availability
  end

  def makeable_ids
    available_counts.select { |cocktail_id, availability| availability[:available] >= availability[:required] }.keys
  end

  def cocktail_availability(cocktail)
    availability = @availability_map[cocktail.id]
    {
      available: availability.sum { |required, reagents| reagents.any? { |bottle| bottle.current_volume >= required.required_volume } ? 1 : 0 },
      required: availability.keys.count
    }
  end

  def available_counts
    @cocktails.reduce({}) do |memo, cocktail|
      memo[cocktail.id] = cocktail_availability(cocktail)
      memo
    end
  end

  private

  def preload_reagents_for_user
    all_tags = @cocktails.includes(:reagent_amounts).flat_map(&:reagent_amounts).pluck(:tags).flatten

    Reagent.for_user(@current_user).with_tags(all_tags).reduce({}) do |memo, reagent|
      reagent.tags.each do |tag|
        memo[tag] ||= []
        memo[tag] << reagent
      end
      memo
    end
  end

  def setup_availability
    @cocktails.includes(:reagent_amounts).reduce({}) do |memo, cocktail|
      memo[cocktail.id] = cocktail.reagent_amounts.reduce({}) do |second_memo, required_amount|
        second_memo[required_amount] = required_amount.tags.flat_map { |tag| @reagents_for_user[tag] }.compact
        second_memo
      end
      memo
    end
  end
end