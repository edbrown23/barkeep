# == Schema Information
#
# Table name: reagent_amounts
#
#  id          :bigint           not null, primary key
#  recipe_id   :bigint
#  amount      :decimal(10, 2)   not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  unit        :string           not null
#  description :text
#  user_id     :bigint
#  tags        :string           default([]), is an Array
#
# Indexes
#
#  index_reagent_amounts_on_recipe_id  (recipe_id)
#  index_reagent_amounts_on_user_id    (user_id)
#
class ReagentAmount < ApplicationRecord
  include UserScopable
  include Taggable

  belongs_to :recipe

  measured Measured::Volume, :required_volume, value_field_name: :amount, unit_field_name: :unit

  validates :required_volume, measured: true

  def reagent_categories
    ReagentCategory.where(external_id: tags)
  end

  def matching_reagents
    Reagent.with_tags(tags)
  end

  def reagent_available?(current_user)
    matching_reagents(current_user).all? do |required, available|
      available.present? && available.any? { |bottle| bottle.current_volume > required.required_volume }
    end
  end

  def unitless?
    unit == 'unknown'
  end
end
