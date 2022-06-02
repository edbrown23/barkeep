# == Schema Information
#
# Table name: reagent_amounts
#
#  id                  :bigint           not null, primary key
#  recipe_id           :bigint
#  amount              :decimal(, )
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  reagent_category_id :bigint           not null
#  unit                :string
#  description         :text
#  user_id             :bigint
#
# Indexes
#
#  index_reagent_amounts_on_reagent_category_id  (reagent_category_id)
#  index_reagent_amounts_on_recipe_id            (recipe_id)
#  index_reagent_amounts_on_user_id              (user_id)
#
class ReagentAmount < ApplicationRecord
  include UserScopable

  belongs_to :recipe
  belongs_to :reagent_category, optional: true

  def reagent_available?
     reagent_category.category_available?(amount)
  end
end
