require 'csv'
require 'hpricot'
require 'open-uri'

class Page
  def raw_parse
    @raw_parse ||= fetch do |f|
      Hpricot(f)
    end
  end

  def fetch
    yield open("#{base_url}#{page_url}")
  end

  def page_url
    raise 'Undefined'
  end

  def base_url
    'https://tuxedono2.com'
  end
end

class IndexPage < Page
  def cocktails
    @cocktails ||= begin
      a_records = raw_parse.search('a')

      a_records.filter! { |l| !l['href'].starts_with?('/ingredients/') }
      a_records.filter! { |l| l['href'].include?('cocktail-recipe') }
      # These are the nice images next to drinks which are duplicates
      a_records.filter! { |l| l.search('img').blank? } 

      a_records.map do |cocktail_link|
        {
          name: cocktail_link.inner_html,
          detail_url: cocktail_link['href']
        }
      end
    end
  end

  def page_url
    '/index'
  end
end

class CocktailPage < Page
  NON_VOLUME_UNITS = ['lb']

  attr_reader :page_url

  def initialize(name, cocktail_url)
    @name = name
    @page_url = cocktail_url
  end

  def ingredients
    @ingredients ||= begin
      ingredients_list = raw_parse.search("div.recipe__recipe").search('li')

      ingredients_list.filter! { |ingredient| ingredient.search('.amount').present? }

      puts "parsing ingredients for cocktail: #{@name}"
      ingredients_list.map do |ingredient|
        puts "parsing ingredient row: #{ingredient.inner_text}"
        amount_blob = ingredient.at('.amount')
        entire_amount_string = amount_blob.inner_text
        unit_string = amount_blob.at('span')&.inner_html || ''
        specific_amount_string = entire_amount_string.gsub(unit_string, '')

        specific_amount = specific_amount_string.to_f
        if specific_amount_string.ends_with?('½')
          specific_amount += 0.5
        end

        if specific_amount_string.ends_with?('¾')
          specific_amount += 0.75
        end
        
        if specific_amount_string.ends_with?('¼')
          specific_amount += 0.25
        end

        if specific_amount == 0.0
          puts "#{ingredient.inner_text} unparseable volume. Assuming 1 #{unit_string}"
          specific_amount = 1.0
        end

        if unit_string.blank? || NON_VOLUME_UNITS.include?(unit_string)
          puts "#{ingredient.inner_text} unparseable unit. Assuming #{specific_amount} unknowns"
          unit_string = 'unknown'
        end

        ingredient_blob = ingredient.at('.ingredient')

        {
          name: (ingredient_blob.at('a') || ingredient_blob).inner_html.strip,
          amount: specific_amount,
          unit: unit_string.strip,
          amount_string: ingredient.inner_text
        }
      end
    end
  end
end

namespace :source_things do
  desc 'Pull cocktails from tuxedono2.com'
  task tuxedono2: [:environment] do
    index = IndexPage.new

    cocktails = index.cocktails
    count = 0
    ApplicationRecord.transaction do
      cocktails.each do |cocktail_link|
        puts "sleeping"
        sleep(3)
        page = CocktailPage.new(cocktail_link[:name], cocktail_link[:detail_url])
        ingredients = page.ingredients

        maybe_recipe = Recipe.find_by(name: cocktail_link[:name])
        if maybe_recipe.present?
          puts "Already have a #{maybe_recipe.name}, skipping"
          next
        end

        recipe = Recipe.create!(
          name: cocktail_link[:name],
          category: 'cocktail',
          user_id: 1
        )

        ingredients.each do |ingredient|
          # look for matching categories first
          category_record = ReagentCategory.find_or_create_by(name: ingredient[:name].strip.titleize) do |category_record|
            # if ingredient[:amount_string].downcase.include?('garnish')
            #   reagent_record.current_volume_percentage = 1.0
            # else
            #   reagent_record.current_volume_percentage = 0.0
            # end
            # reagent_record.max_volume = 750
          end

          begin
            ReagentAmount.create!(
              recipe: recipe,
              amount: ingredient[:amount],
              unit: ingredient[:unit],
              reagent_category: category_record,
              description: ingredient[:amount_string],
              user_id: 1
            )
          rescue => e
            binding.pry
            raise e
          end
        end

        count += 1
        puts "Added #{count} cocktails"
      end
    end
  end
end