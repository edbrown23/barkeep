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

  def matching_reagents(current_user)
    Reagent.for_user(current_user).with_tags(tags)
  end

  def reagent_availability(current_user)
    matching_reagents(current_user).map do |reagent|
      {
        available: reagent.current_volume,
        required: required_volume,
        enough: reagent.current_volume >= required_volume
      }
    end.tap do |matching|
      # Unitless reagents are always available
      if unitless?
        matching << {
          available: required_volume,
          required: required_volume,
          enough: true,
          garnish: true
        }
      end
    end
  end

  def unitless?
    unit == 'unknown'
  end
end
