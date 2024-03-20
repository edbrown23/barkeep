# == Schema Information
#
# Table name: recipes
#
#  id               :bigint           not null, primary key
#  name             :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  category         :string           not null
#  description      :text
#  extras           :jsonb
#  user_id          :bigint
#  parent_id        :bigint
#  source           :string           default("")
#  ingredients_blob :jsonb
#  searchable       :tsvector
#  embedding        :vector(500)
#
# Indexes
#
#  index_recipes_on_parent_id   (parent_id)
#  index_recipes_on_searchable  (searchable) USING gin
#  index_recipes_on_user_id     (user_id)
#
class Recipe < ApplicationRecord
  include UserScopable
  include PgSearch::Model

  pg_search_scope :private_by_tag, against: :searchable, using: { tsearch: { dictionary: :simple, tsvector_column: :searchable } }
  scope :by_tag, ->(*tag_string) { private_by_tag(tag_string.map { |t| t.gsub('_', '/') }) }

  Ingredient = Struct.new(:tags, :amount, :unit, :description, :reagent_amount_id, :optional, keyword_init: true) do
    def unitless?
      unit == 'unknown'
    end

    def required_volume
      Measured::Volume.new(amount, unit)
    end

    def reagent_amount
      ReagentAmount.find(reagent_amount_id)
    end

    def optional?
      optional.nil? ? false : optional
    end
  end

  has_many :reagent_amounts, dependent: :destroy
  has_many :audits
  belongs_to :parent, class_name: Recipe.name, primary_key: :id, optional: true
  has_many :children, class_name: Recipe.name, foreign_key: :parent_id
  has_many :cocktail_family_joiners
  has_many :cocktail_families, through: :cocktail_family_joiners
  has_neighbors :embedding, normalize: true

  jsonb_accessor :extras, proposed_to_be_shared: :boolean, proposer_user_id: :integer

  def ingredients
    @ingredients ||= ingredients_blob.fetch('ingredients', []).map do |i|
      Ingredient.new(
        tags: i['tags'],
        amount: i['amount'],
        unit: i['unit'],
        reagent_amount_id: i['reagent_amount_id'],
        optional: i['optional']
      )
    end
  end

  def global_cocktail_families
    cocktail_families.for_user(nil)
  end

  # this does not make sense as a use for this operator
  def <<(ingredient)
    ingredients_blob['ingredients'] ||= []
    ingredients_blob['ingredients'] << {
      tags: ingredient.tags,
      amount: ingredient.amount,
      unit: ingredient.unit,
      reagent_amount_id: ingredient.reagent_amount_id,
      optional: ingredient.optional
    }
  end

  def tags
    ingredients.flat_map { |i| i.tags }
  end

  def clear_ingredients
    ingredients_blob.clear()
  end

  def matching_reagents(current_user = nil)
    tags_array = reagent_amounts.pluck(:tags).flatten
    reagents = Reagent.for_user(current_user).with_tags(tags_array)
    reagent_amounts.reduce({}) do |memo, required_amount|
      memo[required_amount] ||= reagents.select { |r| (r.tags & required_amount.tags).present? }
      memo
    end
  end

  def user_can_make?(current_user)
    service = CocktailAvailabilityService.new(Recipe.where(id: self.id), current_user)
    availability = service.cocktail_availability(self)
    availability[:required] - availability[:available] <= 0
  end

  def ephemeral?
    source == 'drink_builder'
  end
end
