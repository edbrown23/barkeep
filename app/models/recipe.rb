# == Schema Information
#
# Table name: recipes
#
#  id          :bigint           not null, primary key
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  category    :string           not null
#  description :text
#  extras      :jsonb
#  user_id     :bigint
#
# Indexes
#
#  index_recipes_on_user_id  (user_id)
#
class Recipe < ApplicationRecord
  include UserScopable

  has_many :reagent_amounts, dependent: :destroy
  has_many :audits, dependent: :destroy

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

  def matching_reagents(current_user = nil)
    tags_array = reagent_amounts.pluck(:tags).flatten
    reagents = Reagent.for_user(current_user).with_tags(tags_array)
    reagent_amounts.reduce({}) do |memo, required_amount|
      memo[required_amount] ||= reagents.select { |r| (r.tags & required_amount.tags).present? }
      memo
    end
  end

  # I bet using scopes for this is just wrong
  scope :all_available, ->(current_user) do
    # iterate recipes
    # check if I have enough volume in every reagent in the cocktail to make it
    all_cocktails = where(category: 'cocktail')
    all_cocktails.filter do |cocktail|
      cocktail.matching_reagents(current_user).all? do |required, available|
        available.present? && available.any? { |bottle| bottle.current_volume > required.required_volume }
      end
    end
  end
end
