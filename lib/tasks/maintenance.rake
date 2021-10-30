require 'csv'

namespace :maintenance do
  desc 'Import cocktail recipes from a csv file'
  task import_cocktails: [:environment] do
    cocktails_csv = ENV.fetch('csv')

    REAGENT_HEADERS = ['reagent_1', 'reagent_2', 'reagent_3', 'reagent_4']

    CSV.read(cocktails_csv, headers: true).each do |row|
      # TODO: this should use the cool tty thing or whatever to ask if you want to override shit
      name = row['name']
      reagents = []

      # make the cocktail recipe model
      cocktail = Recipe.create!(name: name)

      # parse reagents
      REAGENT_HEADERS.each do |reagent_key|
        reagent_name = row["#{reagent_key}_name"]
        reagent_amount = row["#{reagent_key}_amount"]
        if reagent_name.present?
          reagents << {
            reagent_name: reagent_name,
            reagent_amount: reagent_amount
          }
        end
      end

      # load or create reagent models
      reagents.each do |reagent|
        # I bet I could find_or_create_by
        maybe_reagent = Reagent.find_by(name: reagent[:reagent_name])
        binding.pry

        if maybe_reagent.present?
          reagent[:reagent_model] = maybe_reagent

          next
        end

        reagent[:reagent_model] = Reagent.create!(
          name: reagent[:reagent_name],
          current_volume_percentage: 0.0,
        )
      end

      # create reagent amounts
      reagents.each do |reagent|
        ReagentAmount.create!(
          recipe: cocktail,
          reagent: reagent[:reagent_model],
          amount: reagent[:reagent_amount]
        )
      end

      puts "Created #{cocktail.name}"
    end
  end
end