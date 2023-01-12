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
#  external_id          :string           not null
#  tags                 :string           default([]), is an Array
#
# Indexes
#
#  index_reagents_on_external_id_and_user_id  (external_id,user_id) UNIQUE
#  index_reagents_on_name                     (name) UNIQUE
#  index_reagents_on_user_id                  (user_id)
#

class Reagent < ApplicationRecord
  include UserScopable
  include Taggable

  measured Measured::Volume, :max_volume
  measured Measured::Volume, :current_volume

  validates :name, uniqueness: { scope: :user_id }
  validates :external_id, uniqueness: { scope: :user_id }

  validates :max_volume, measured: true
  validates :current_volume, measured: true

  def subtract_usage(amount)
    new_current = current_volume - amount

    if new_current.value <= 0.0
      update!(current_volume_value: 0)
    else
      update!(current_volume_value: new_current.value)
    end
  end

  def unitless?
    max_volume_unit == 'unknown'
  end
end
