# == Schema Information
#
# Table name: reference_bottles
#
#  id                  :bigint           not null, primary key
#  name                :string           not null
#  cost_reference      :decimal(, )
#  description         :string
#  main_image_url      :string
#  reagent_category_id :bigint
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_reference_bottles_on_reagent_category_id  (reagent_category_id)
#
class ReferenceBottle < ApplicationRecord
  belongs_to :reagent_category
end
