class RecipeEmbeddingsService
  def self.generate(recipe)
    distances = recipe.reagent_amounts.flat_map do |amount|
      dimensions = ReagentCategory.where(external_id: amount.tags).map do |category|
        oz_amount = amount.required_volume.convert_to('oz')
        [category.dimension, oz_amount]
      end
    end.to_h
    length = Math.sqrt(distances.values.sum { |amount| amount.value * amount.value })
    dimensions_array = [0] * 500
    distances.each do |id, amount|
      dimensions_array[id - 1] = amount.value / length
    end

    dimensions_array
  end
end