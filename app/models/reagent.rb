# == Schema Information
#
# Table name: reagents
#
#  id                   :bigint           not null, primary key
#  name                 :string
#  cost                 :decimal(, )
#  purchase_location    :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  description          :text
#  user_id              :bigint
#  max_volume_unit      :string           not null
#  max_volume_value     :decimal(10, 2)   not null
#  current_volume_value :decimal(10, 2)   not null
#  current_volume_unit  :string           not null
#  reagent_category_id  :bigint
#  external_id          :string           not null
#
# Indexes
#
#  index_reagents_on_external_id  (external_id) UNIQUE
#  index_reagents_on_name         (name) UNIQUE
#  index_reagents_on_user_id      (user_id)
#

class Reagent < ApplicationRecord
  include UserScopable

  # TODO: validations that ensure the percentage is between 0 and 1
  belongs_to :reagent_category

  OUNCES_TO_ML_CONSTANT = 29.574 # I got this conversion constant from google

  measured Measured::Volume, :max_volume
  measured Measured::Volume, :current_volume

  validates :max_volume, measured: true
  validates :current_volume, measured: true

  def ounces_available
    (current_volume_percentage * max_volume) / OUNCES_TO_ML_CONSTANT
  end

  def subtract_ounces(ounces)
    new_ounces_available = ounces_available - ounces

    new_ounces_available = 0.0 if new_ounces_available < 0.0

    new_percentage = (new_ounces_available * OUNCES_TO_ML_CONSTANT) / max_volume
    update!(current_volume_percentage: new_percentage)
  end

  def unitless?
    max_volume_unit == 'unknown'
  end
end
