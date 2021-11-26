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

class Reagent < ApplicationRecord
  # TODO: validations that ensure the percentage is between 0 and 1
end
