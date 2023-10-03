class BackfillOptionalAmounts < ActiveRecord::Migration[7.0]
  def change
    Recipe.in_batches do |batch|
      batch.each do |recipe|
        Recipe.transaction do 
          blobs = []
          recipe.clear_ingredients
          recipe.reagent_amounts.each do |amount|
            amount.optional = amount.unitless?
            recipe << amount.convert_to_blob
            amount.save!
          end

          recipe.save!
        end
      end
    end
  end
end
