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

  scope :all_available, ->(current_user) do
    # iterate recipes
    # check if I have enough volume in every reagent in the cocktail to make it
    all_cocktails = where(category: 'cocktail').includes(reagent_amounts: [{ reagent_category: :reagents }])
    all_cocktails.filter do |cocktail|
      cocktail.reagent_amounts.all? do |amount|
        amount.reagent_category.user_has_reagent?(current_user, amount)
      end
    end
  end
end
