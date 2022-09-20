# == Schema Information
#
# Table name: reagent_categories
#
#  id          :bigint           not null, primary key
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  description :text
#
# Indexes
#
#  index_reagent_categories_on_name  (name) UNIQUE
#
class ReagentCategory < ApplicationRecord
  has_many :reagents
  has_many :reagent_amounts

  def user_has_reagent?(current_user, amount)
    reagents.for_user(current_user).any? do |reagent|
      if amount.unitless? && reagent.unitless?
        reagent.current_volume >= amount.required_volume
      elsif !amount.unitless? && !reagent.unitless? # TODO wat is this
        reagent.current_volume >= amount.required_volume
      else
        Rails.logger.warn("Mismatched amount classes")
        false
      end
    end
  end
end
