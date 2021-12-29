# == Schema Information
#
# Table name: reagent_amounts
#
#  id                  :bigint           not null, primary key
#  recipe_id           :bigint
#  reagent_id          :bigint
#  amount              :decimal(, )
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  reagent_category_id :bigint
#
# Indexes
#
#  index_reagent_amounts_on_reagent_category_id  (reagent_category_id)
#  index_reagent_amounts_on_reagent_id           (reagent_id)
#  index_reagent_amounts_on_recipe_id            (recipe_id)
#
class ReagentAmount < ApplicationRecord
  belongs_to :recipe
  belongs_to :reagent
  has_one :reagent_category
end
