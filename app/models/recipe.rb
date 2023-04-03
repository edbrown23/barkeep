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
#
# Indexes
#
#  index_recipes_on_parent_id  (parent_id)
#  index_recipes_on_user_id    (user_id)
#
class Recipe < ApplicationRecord
  include UserScopable

  Ingredient = Struct.new(:tags, :amount, :unit, :reagent_amount_id, keyword_init: true) do
    def reagent_amount
      ReagentAmount.find(reagent_amount_id)
    end
  end

  has_many :reagent_amounts, dependent: :destroy
  has_many :audits
  belongs_to :parent, class_name: Recipe.name, primary_key: :id, optional: true
  has_many :children, class_name: Recipe.name, foreign_key: :parent_id

  class << self
    # could be a module, plus this is all probabyl dumb and a gem or whatever
    def extra_column(name, default = nil)
      define_method(name) do
        (extras || {})[name.to_s] || default
      end

      define_method("#{name}=") do |value|
        self.extras ||= {}
        self.extras[name.to_s] = value
      end
    end
  end

  extra_column :favorite, false
  extra_column :proposed_to_be_shared, false
  extra_column :proposer_user_id, nil

  def ingredients
    @ingredients ||= ingredients_blob.fetch('ingredients', []).map do |i|
      Ingredient.new(
        tags: i['tags'],
        amount: i['amount'],
        unit: i['unit'],
        reagent_amount_id: i['reagent_amount_id']
      )
    end
  end

  # this does not make sense as a use for this operator
  def <<(ingredient)
    ingredients_blob['ingredients'] ||= []
    ingredients_blob['ingredients'] << {
      tags: ingredient.tags,
      amount: ingredient.amount,
      unit: ingredient.unit,
      reagent_amount_id: ingredient.reagent_amount_id
    }
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
