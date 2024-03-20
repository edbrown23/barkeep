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

  desc 'Import reagents from csv file (replaces existing reagents)'
  task import_reagents: [:environment] do
    reagents_csv = ENV.fetch('csv')

    Reagent.transaction do
      CSV.read(reagents_csv, headers: true, return_headers: true).each do |row|
        potential_category_name = row['Category'] || row['Name']
        category_id = Lib.to_external_id(potential_category_name)
        category_model = ReagentCategory.find_or_create_by(external_id: category_id) do |created_model|
          created_model.name = potential_category_name
        end

        Reagent.create!(
          user: User.find_by(email: 'eric.d.brown23@gmail.com'),
          name: row['Name'],
          max_volume_value: row['Max Volume'],
          max_volume_unit: 'ml',
          current_volume_value: (row['Current Volume'].to_i / 100.0) * row['Max Volume'].to_i,
          current_volume_unit: 'ml',
          external_id: Lib.to_external_id(row['Name']),
          tags: [category_id]
        )
      end
    end
  end

  desc 'Hoist ingredient info from ReagentAmounts to Recipes'
  task hoist_reagent_amounts: [:environment] do
    user_id = ENV.fetch('user_id', nil)

    initial_scope = user_id.present? ? Recipe.for_user(User.find(user_id)) : Recipe.for_user(nil)

    initial_scope.includes(:reagent_amounts).in_batches do |recipes|
      recipes.each do |recipe|
        Recipe.transaction do
          recipe.clear_ingredients

          recipe.reagent_amounts.each { |ra| recipe << ra.convert_to_blob }

          recipe.save!
          Rails.logger.info("Hoisted #{recipe.name}")
        end
      end
    end
  end

  desc 'Setup embeddings on recipes'
  task setup_embeddings: [:environment] do
    Recipe.all.each do |recipe|
      recipe.update(embedding: RecipeEmbeddingsService.generate(recipe))
    end
  end
end
