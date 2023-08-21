class CocktailCounter

  # @param cocktail: Recipe
  #
  # Given a cocktail (or recipe), returns how many the user can make
  # with their reagents.
  def self.count_possible_cocktails(cocktail, user)
    cocktail.matching_reagents(user).map do |amount, reagents|
      next if amount.unitless?

      total_amount = reagents.map(&:current_volume).reduce(&:+)&.convert_to(:ml) || Measured::Volume.new(0, :ml)
      cocktail_amount = amount.required_volume.convert_to(:ml)

      total_amount.value.to_i / cocktail_amount.value.to_i
    end.compact.min
  end
end

