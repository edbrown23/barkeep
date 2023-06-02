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
    available_tags = []
    under_volume_tags = []
    unitless_tags = []
    available_bottles = availability.sum do |required, reagents|
      unitless_tags.concat(required.tags) if required.unitless?
      reagents.any? do |bottle|
        (bottle.current_volume >= required.required_volume).tap do |available|
          available ? available_tags.concat(required.tags) : under_volume_tags.concat(required.tags)
        end
      end || required.unitless? ? 1 : 0
    end
    {
      available: available_bottles,
      required: availability.keys.count,
      missing_tags: availability.keys.flat_map(&:tags).uniq - available_tags.uniq - unitless_tags.uniq,
      unitless_tags: unitless_tags.uniq,
      under_volume_tags: under_volume_tags
    }
  end

  def available_counts
    @available_counts ||= @cocktails.reduce({}) do |memo, cocktail|
      memo[cocktail.id] = cocktail_availability(cocktail)
      memo
    end
  end

  private

  # gets all the user's reagents which match a tag
  def preload_reagents_for_user
    Reagent.for_user(@current_user).reduce({}) do |memo, reagent|
      reagent.tags.each do |tag|
        memo[tag] ||= []
        memo[tag] << reagent
      end
      memo
    end
  end

  def setup_availability
    @cocktails.reduce({}) do |memo, cocktail|
      memo[cocktail.id] = cocktail.ingredients.reduce({}) do |second_memo, required_amount|
        second_memo[required_amount] = required_amount.tags.flat_map { |tag| @reagents_for_user[tag] }.compact
        second_memo
      end
      memo
    end
  end
end