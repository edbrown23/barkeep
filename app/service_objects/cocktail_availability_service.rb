class CocktailAvailabilityService
  attr_reader :cocktails, :reagents_for_user, :availability_map

  def initialize(cocktails, current_user, shopping_list = nil)
    @cocktails = cocktails
    @current_user = current_user
    @available_favorites = setup_available_favorites if current_user.present?
    @shopping_list = shopping_list
    @reagents_for_user = preload_reagents_for_user
    @availability_map = setup_availability
  end

  def setup_available_favorites
    Recipe.where(id: CocktailFamilyJoiner.available_favorite_from(@current_user, cocktails.map(&:id)).map(&:recipe_id))
  end

  def makeable_ids
    available_counts.select { |cocktail_id, availability| availability[:available] >= availability[:required] }.keys
  end

  def cocktail_availability(cocktail)
    availability = @availability_map[cocktail.id]
    available_tags = []
    under_volume_tags = []
    optional_tags = []
    available_bottles = availability.sum do |required, reagents|
      optional_tags.concat(required.tags) if required.optional?
      reagents.any? do |bottle|
        (bottle.current_volume >= required.required_volume).tap do |available|
          available ? available_tags.concat(required.tags) : under_volume_tags.concat(required.tags)
        end
      end || required.optional? ? 1 : 0
    end
    {
      available: available_bottles,
      required: availability.keys.count,
      missing_tags: availability.keys.flat_map(&:tags).uniq - available_tags.uniq - optional_tags.uniq,
      optional_tags: optional_tags.uniq,
      under_volume_tags: under_volume_tags
    }
  end

  def available_counts
    @available_counts ||= @cocktails.reduce({}) do |memo, cocktail|
      memo[cocktail.id] = cocktail_availability(cocktail)
      memo
    end
  end

  def count_favorites
    @available_favorites.reduce({}) do |hsh, cocktail|
      ingredients_to_available = @availability_map[cocktail.id]
      minimum_count = ingredients_to_available.map do |ingredient, user_reagents|
        required = ingredient.required_volume.convert_to(:ml)
        users_min = user_reagents.map(&:current_volume).max

        next nil if ingredient.unit == 'unknown'
        next 0 if users_min.nil?

        (users_min.value / required.value).floor
      end.compact.min
      hsh[cocktail] = minimum_count
      hsh
    end
  end

  private

  # Fetches all the current user's reagents and groups
  # them by tag. Returns a hash of tag to list of matching
  # reagents.
  #
  # @returns Hash<Symbol: Array[Reagent]
  def preload_reagents_for_user
    Reagent.for_user(@current_user).where(shopping_list_id: [@shopping_list&.id, nil].uniq).reduce({}) do |memo, reagent|
      reagent.tags.each do |tag|
        memo[tag] ||= []
        memo[tag] << reagent
      end
      memo
    end
  end

  # I believe this returns a hash of recipe id (or cocktail id) to
  # a hash of Ingredients to Reagents. The returned reagents are user
  # specific, allowing us to know whether the user has the necessary
  # reagents to make a cocktail.

  # @returns Hash<Int, Hash<Ingredient: Reagent>
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
