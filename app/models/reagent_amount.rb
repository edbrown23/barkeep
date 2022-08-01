# == Schema Information
#
# Table name: reagent_amounts
#
#  id                  :bigint           not null, primary key
#  recipe_id           :bigint
#  amount              :decimal(10, 2)   not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  reagent_category_id :bigint           not null
#  unit                :string           not null
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

  measured Measured::Volume, :required_volume, value_field_name: :amount, unit_field_name: :unit

  validates :required_volume, measured: true

  def reagent_available?(current_user)
     reagent_category.user_has_reagent?(current_user, self)
  end

  def unitless?
    unit == 'unknown'
  end
end
