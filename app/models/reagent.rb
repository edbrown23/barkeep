# == Schema Information
#
# Table name: reagents
#
#  id                        :bigint           not null, primary key
#  name                      :string
#  cost                      :decimal(, )
#  purchase_location         :string
#  max_volume                :decimal(, )
#  current_volume_percentage :decimal(, )
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  reagent_category_id       :bigint
#  description               :text
#  user_id                   :bigint
#
# Indexes
#
#  index_reagents_on_reagent_category_id  (reagent_category_id)
#  index_reagents_on_user_id              (user_id)
#

class Reagent < ApplicationRecord
  include UserScopable

  # TODO: validations that ensure the percentage is between 0 and 1
  belongs_to :reagent_category, optional: true

  OUNCES_TO_ML_CONSTANT = 29.574 # I got this conversion constant from google

  def ounces_available
    (current_volume_percentage * max_volume) / OUNCES_TO_ML_CONSTANT
  end

  def subtract_ounces(ounces)
    new_ounces_available = ounces_available - ounces

    new_ounces_available = 0.0 if new_ounces_available < 0.0

    new_percentage = (new_ounces_available * OUNCES_TO_ML_CONSTANT) / max_volume
    update!(current_volume_percentage: new_percentage)
  end
end
